class Message < ActiveRecord::Base

  belongs_to :allocation_tag
  has_one :group, through: :allocation_tag

  has_many :files, class_name: 'MessageFile'
  has_many :users, -> { uniq }, through: :user_messages
  has_many :user_messages
  has_many :user_message_labels, -> { uniq }, through: :user_messages
  has_many :message_labels, -> { uniq }, through: :user_message_labels

  before_save proc { |record| record.subject = I18n.t(:no_subject, scope: :messages) if record.subject == '' }
  before_save :set_sender_and_recipients, if: 'sender'

  scope :by_user, ->(user_id) { joins(:user_messages).where(user_messages: { user_id: user_id }) }

  accepts_nested_attributes_for :user_messages, allow_destroy: true
  accepts_nested_attributes_for :files, allow_destroy: true

  validates :content, presence: true
  validates :subject, length: {minimum: 0, maximum: 255}, presence: true

  self.per_page = Rails.application.config.items_per_page

  attr_accessor :contacts, :sender, :api

  def sent_by
    user_messages.where("cast(user_messages.status & #{Message_Filter_Sender} as boolean)").first.user
  end

  def recipients
    users.where("NOT cast(user_messages.status & #{Message_Filter_Sender} as boolean)")
  end

  def labels(user_id = nil, system_label = true)
    l = []
    l << message_labels.where(user_id: user_id).pluck(:name) if user_id # label criada pelo usuário (funcionalidade futura)
    l << group.as_label if system_label && allocation_tag_id # label pela turma (default do sistema)
    l.flatten.compact.uniq
  end

  def self.get_query(user_id, box='inbox', allocation_tags_ids=[], options={ ignore_trash: true, only_unread: false, only_read: false, ignore_user: false, ignore_at: false }, search={})
    query = []
    case box
    when 'inbox'
      query << "NOT cast(user_messages.status & #{Message_Filter_Sender + Message_Filter_Trash} as boolean)"
    when 'outbox'
      query << "cast(user_messages.status & #{Message_Filter_Sender} as boolean)"
      query << "NOT cast(user_messages.status & #{Message_Filter_Trash} as boolean)" if options[:ignore_trash]
    when 'trashbox'
      query << "cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    end
    query << "NOT cast(user_messages.status & #{Message_Filter_Read} as boolean)" if options[:only_unread]
    query << "cast(user_messages.status & #{Message_Filter_Read} as boolean)" if options[:only_read]

    ats = [allocation_tags_ids].flatten.compact

    query << "messages.allocation_tag_id IN (#{ats.join(',')})" unless ats.blank? || options[:ignore_at]
    query << "user_messages.user_id = #{user_id}" unless options[:ignore_user]
    query << "position(lower(unaccent('#{search[:subject]}')) in lower(unaccent(messages.subject))) > 0 " unless search[:subject].blank?

    query.join(' AND ')
  end

  def self.by_box(user_id, box='inbox', allocation_tags_ids=[], options={ ignore_trash: true, only_unread: false, only_read: false, ignore_user: false, page: 1, ignore_at: false }, search={}, limit=nil, offset=nil)
    um_query = Message.get_query(user_id, box, allocation_tags_ids, options.except(:ignore_at))
    limit = Rails.application.config.items_per_page.to_i if limit.nil?
    offset = ((options[:page] || 1) * limit) - limit.to_i if offset.nil?

    UserMessage.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_user_messages;
    SQL
    UserMessage.find_by_sql <<-SQL
      CREATE TEMPORARY TABLE temp_user_messages AS
      SELECT user_messages.id, message_id, user_id, status
      FROM user_messages
      LEFT JOIN messages ON messages.id = user_messages.message_id
      WHERE #{um_query};
    SQL

    UserMessage.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_user_messages2;
    SQL
    UserMessage.find_by_sql <<-SQL
      CREATE TEMPORARY TABLE temp_user_messages2 AS
      SELECT message_id, user_id, status
      FROM user_messages
      WHERE message_id IN (SELECT message_id FROM temp_user_messages);
    SQL

    query = Message.get_query(user_id, box, allocation_tags_ids, options, search)

    select_query = (box == 'outbox' ? 'sent_to.name AS sent_to_names,' : 'sent_by.name AS sent_by_name,')
    user_query = ''
    user_query = (box == 'outbox' ? "" : " AND position(lower(unaccent('#{search[:user]}')) in lower(unaccent(users.name))) > 0") unless search[:user].blank?
    query << (box == 'outbox' ? " AND position(lower(unaccent('#{search[:user]}')) in lower(unaccent(sent_to.name))) > 0" : " AND position(lower(unaccent('#{search[:user]}')) in lower(unaccent(sent_by.name))) > 0") unless search[:user].blank?
    group_query = (box == 'outbox' ? ', sent_to.name' : ', sent_by.name')

    join_query =  if box == 'outbox'
      <<-SQL
        LEFT JOIN (
          SELECT replace(replace(translate(array_agg(distinct users.name)::text,'{}', ''),'\"', ''),',',', ') AS name, um1.message_id AS id
            FROM users
            JOIN temp_user_messages2 um1 ON um1.user_id    = users.id
            JOIN temp_user_messages2 um2 ON um2.message_id = um1.message_id
            WHERE cast(um2.status & #{Message_Filter_Sender} as boolean)
            AND (um1.status = 0 OR um1.status = 2 OR cast(um2.status & #{Message_Filter_Read + Message_Filter_Trash} as boolean))
            AND um2.user_id = #{user_id}
            GROUP BY um1.message_id
        ) sent_to ON sent_to.id = messages.id
      SQL
    else
      <<-SQL
        LEFT JOIN (
          SELECT users.name AS name, um.message_id AS id
            FROM users
            JOIN temp_user_messages2 um ON um.user_id = users.id
            WHERE cast(um.status & #{Message_Filter_Sender} as boolean) #{user_query}
        ) sent_by ON sent_by.id = messages.id
      SQL
    end

    msgs = Message.find_by_sql <<-SQL
      SELECT DISTINCT messages.id, messages.*, count(*) OVER() AS total_messages, sum(unreaded_messages.unread) OVER() AS unread,
        #{select_query}
        COUNT(message_files.id) AS count_files,
        COUNT(unreaded_messages.unread) AS wasnt_read
      FROM messages
      JOIN temp_user_messages AS user_messages ON messages.id = user_messages.message_id
      LEFT JOIN message_files ON messages.id = message_files.message_id
      LEFT JOIN (
        SELECT um.id, 1 AS unread
          FROM temp_user_messages um
          WHERE NOT(
            cast(um.status & #{Message_Filter_Read} as boolean)
            OR cast(um.status & #{Message_Filter_Sender} as boolean)
          )
      ) unreaded_messages ON unreaded_messages.id = user_messages.id
      #{join_query}
      WHERE #{query}
      GROUP BY user_messages.status, user_messages.user_id, messages.id, unreaded_messages.unread #{group_query}
      ORDER BY created_at DESC
      LIMIT #{limit.to_i}
      OFFSET #{offset.to_i};
    SQL


    UserMessage.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_user_messages2;
    SQL
    UserMessage.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_user_messages;
    SQL

    msgs
  end

  def self.get_count_unread_in_inbox(user_id, allocation_tags_ids=[], options={ ignore_user: false, ignore_at: false }, search={})
    ats = [allocation_tags_ids].flatten.compact
    query = []
    query << "NOT(cast(user_messages.status & #{Message_Filter_Read} as boolean) OR cast(user_messages.status & #{Message_Filter_Sender} as boolean) OR cast(user_messages.status & #{Message_Filter_Trash} as boolean))"
    query << "messages.allocation_tag_id IN (#{ats.join(',')})" unless ats.blank? || options[:ignore_at]
    query << "user_messages.user_id = #{user_id}" unless options[:ignore_user]
    query << "position(lower(unaccent('#{search[:subject]}')) in lower(unaccent(messages.subject))) > 0 " unless search[:subject].blank?
    Message.joins(:user_messages).where(query.join(' AND ')).select("DISTINCT messages.id").count
  end

  def user_has_permission?(user_id)
    user_messages.where(user_id: user_id).count > 0
  end

  private

    def set_sender_and_recipients
      users = [{user: sender, status: Message_Filter_Sender}]
      if api
        users << contacts.map {|u| {user_id: u.id, status: Message_Filter_Receiver}} unless contacts.blank?
        users.flatten!
      else
        users << contacts.split(",").map {|u| {user_id: u, status: Message_Filter_Receiver}} unless contacts.blank?
      end

      self.user_messages.build users
    end

end
