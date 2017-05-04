class Message < ActiveRecord::Base

  belongs_to :allocation_tag
  has_one :group, through: :allocation_tag

  has_many :files, class_name: 'MessageFile'
  has_many :users, through: :user_messages, uniq: true
  has_many :user_messages
  has_many :user_message_labels, through: :user_messages, uniq: true
  has_many :message_labels, through: :user_message_labels, uniq: true

  before_save proc { |record| record.subject = I18n.t(:no_subject, scope: :messages) if record.subject == '' }
  before_save :set_sender_and_recipients, if: 'sender'

  scope :by_user, ->(user_id) { joins(:user_messages).where(user_messages: { user_id: user_id }) }

  accepts_nested_attributes_for :user_messages, allow_destroy: true
  accepts_nested_attributes_for :files, allow_destroy: true

  validates :content, presence: true
  validates :subject, length: {minimum: 0, maximum: 255}, presence: true

  self.per_page = Rails.application.config.items_per_page

  attr_accessor :contacts, :sender

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

  def self.get_query(user_id, box='inbox', allocation_tags_ids=[], options={ ignore_trash: true, only_unread: false, ignore_user: false }, search={})
    query = []
    case box
    when 'inbox'
      query << "NOT cast(user_messages.status & #{Message_Filter_Sender + Message_Filter_Trash} as boolean)"
      query << "NOT cast(user_messages.status & #{Message_Filter_Read} as boolean)" if options[:only_unread]
    when 'outbox'
      query << "cast(user_messages.status & #{Message_Filter_Sender} as boolean)"
      query << "NOT cast(user_messages.status & #{Message_Filter_Trash} as boolean)" if options[:ignore_trash]
    when 'trashbox'
      query << "cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    end

    ats = [allocation_tags_ids].flatten.compact

    query << "messages.allocation_tag_id IN (#{ats.join(',')})"                                           unless ats.blank?
    query << "user_messages.user_id = #{user_id}"                                                         unless options[:ignore_user]
    query << "position(lower(unaccent('#{search[:subject]}')) in lower(unaccent(messages.subject))) > 0 " unless search[:subject].blank?
    query << (box == 'outbox' ? "position(lower(unaccent('#{search[:user]}')) in lower(unaccent(sent_to2.name))) > 0" : "position(lower(unaccent('#{search[:user]}')) in lower(unaccent(sent_by.name))) > 0") unless search[:user].blank?

    query.join(' AND ')
  end

  def self.by_box(user_id, box='inbox', allocation_tags_ids=[], options={ ignore_trash: true, only_unread: false, ignore_user: false }, search={})
    query = Message.get_query(user_id, box, allocation_tags_ids, options, search)

    Message.find_by_sql <<-SQL
      SELECT DISTINCT messages.id, messages.*, 
        sent_by.name AS sent_by_name,
        replace(replace(translate(array_agg(distinct sent_to.name)::text,'{}', ''),'\"', ''),',',', ') AS sent_to_names,
        COUNT(message_files.id) AS count_files,
        COUNT(readed_messages.id) AS was_read
      FROM messages
      JOIN user_messages      ON messages.id = user_messages.message_id
      LEFT JOIN message_files ON messages.id = message_files.message_id
      LEFT JOIN (
        SELECT um.id
          FROM user_messages um
          WHERE (
            cast(um.status & #{Message_Filter_Read} as boolean) 
            OR cast(um.status & #{Message_Filter_Sender} as boolean)
          )
      ) readed_messages ON readed_messages.id = user_messages.id
      LEFT JOIN (
        SELECT users.name AS name, um.message_id AS id
          FROM users
          JOIN user_messages um ON um.user_id = users.id
          WHERE cast(um.status & #{Message_Filter_Sender} as boolean)
      ) sent_by ON sent_by.id = messages.id
      LEFT JOIN (
        SELECT users.name AS name, um1.message_id AS id
          FROM users
          JOIN user_messages um1 ON um1.user_id    = users.id
          JOIN user_messages um2 ON um2.message_id = um1.message_id
          WHERE cast(um2.status & #{Message_Filter_Sender} as boolean)
          AND (um1.status = 0 OR um1.status = 2 OR cast(um2.status & #{Message_Filter_Read + Message_Filter_Trash} as boolean))
          AND um2.user_id = #{user_id}
      ) sent_to ON sent_to.id = messages.id
      LEFT JOIN (
        SELECT users.name AS name, um1.message_id AS id
          FROM users
          JOIN user_messages um1 ON um1.user_id    = users.id
          JOIN user_messages um2 ON um2.message_id = um1.message_id
          WHERE cast(um2.status & #{Message_Filter_Sender} as boolean)
          AND (um1.status = 0 OR um1.status = 2 OR cast(um2.status & #{Message_Filter_Read + Message_Filter_Trash} as boolean))
          AND um2.user_id = #{user_id}
      ) sent_to2 ON sent_to2.id = messages.id
      WHERE #{query}
      GROUP BY user_messages.status, user_messages.user_id, sent_by.name, messages.id
      ORDER BY created_at DESC;
    SQL
  end

  def self.sent_by_user(user_id, allocation_tags_ids = [])
    Message.count_messages(Message.get_query(user_id, 'outbox', allocation_tags_ids, { ignore_trash: false }))
  end

  def self.unreads(user_id, allocation_tags_ids=[])
    Message.count_messages(Message.get_query(user_id, 'inbox', allocation_tags_ids, { only_unread: true }))
  end

  def self.count_messages(query)
    msgs = Message.find_by_sql <<-SQL
      SELECT COUNT(*) FROM (
        SELECT DISTINCT messages.id
        FROM messages
        JOIN user_messages ON user_messages.message_id = messages.id
        WHERE #{query}
      ) AS msgs;
    SQL

    msgs.first[:count]
  end

  def user_has_permission?(user_id)
    user_messages.where(user_id: user_id).count > 0
  end

  private

    def set_sender_and_recipients
      users = [{user: sender, status: Message_Filter_Sender}]
      users << contacts.split(",").map {|u| {user_id: u, status: Message_Filter_Receiver}} unless contacts.blank?

      self.user_messages.build users
    end

end
