class Message < ActiveRecord::Base
  belongs_to :allocation_tag
  has_one :group, through: :allocation_tag

  has_many :files, class_name: "MessageFile"
  has_many :users, through: :user_messages, uniq: true
  has_many :user_messages
  has_many :user_message_labels, through: :user_messages, uniq: true
  has_many :message_labels, through: :user_message_labels, uniq: true

  accepts_nested_attributes_for :user_messages, allow_destroy: true
  accepts_nested_attributes_for :files, allow_destroy: true

  validates :content, presence: true # :contacts ??

  attr_accessor :contacts

  # box = [inbox, outbox, trashbox]
  def was_read?(user_id, box)
    return false if not ["inbox", "outbox", "trashbox"].include?(box)
    return true if box == "outbox"

    query = case box
    when "inbox" # read AND NOT (trashbox, outbox)
      "cast(user_messages.status & #{Message_Filter_Read} as boolean) AND NOT cast(user_messages.status & #{Message_Filter_Sender} as boolean) AND NOT cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    when "trashbox" # trashbox and (read or sender)
      "cast(user_messages.status & #{Message_Filter_Trash} as boolean) AND (cast(user_messages.status & #{Message_Filter_Read} as boolean) OR cast(user_messages.status & #{Message_Filter_Sender} as boolean))"
    end

    user_messages.where(user_id: user_id).where(query).count > 0
  end

  def has_attachment?
    (files.count > 0)
  end

  def sent_by
    user_messages.where("cast(user_messages.status & #{Message_Filter_Sender} as boolean)").first.user
  end

  def recipients
    users.where("NOT cast(user_messages.status & #{Message_Filter_Sender} as boolean)")
  end

  def labels(user_id = nil, system_label = true)
    l = []
    l << message_labels.where(user_id: user_id).map(&:name) if user_id
    l << group.as_label if system_label and allocation_tag_id # label pela turma (default do sistema)
    l.flatten.compact.uniq
  end

  def self.user_inbox(user_id, allocation_tag_id = nil, only_unread = false)
    query = ["NOT cast(user_messages.status & #{Message_Filter_Sender + Message_Filter_Trash} as boolean)"] # NOT (sender, trash)
    query << "NOT cast(user_messages.status & #{Message_Filter_Read} as boolean)" if only_unread

    where = []
    where = "messages.allocation_tag_id = (#{allocation_tag_id})" unless allocation_tag_id.nil?

    joins(:user_messages).where(user_messages: {user_id: user_id})
      .where(where)
      .where(query.join(" AND ")).order("created_at DESC").uniq
  end

  def self.user_outbox(user_id, allocation_tag_id = nil)
    where = []
    where = "messages.allocation_tag_id = (#{allocation_tag_id})" unless allocation_tag_id.nil?

    joins(:user_messages).where(user_messages: {user_id: user_id})
      .where(where)
      .where("cast(user_messages.status & #{Message_Filter_Sender} as boolean)
        AND NOT cast(user_messages.status & #{Message_Filter_Trash} as boolean)").order("created_at DESC").uniq # sender AND NOT trash
  end

  def self.user_trashbox(user_id, allocation_tag_id = nil)
    where = []
    where = "messages.allocation_tag_id = (#{allocation_tag_id})" unless allocation_tag_id.nil?

    joins(:user_messages).where(user_messages: {user_id: user_id})
      .where(where)
      .where("cast(user_messages.status & #{Message_Filter_Trash} as boolean)").order("created_at DESC").uniq # IN (trash)
  end

  def user_has_permission?(user_id)
    user_messages.where(user_id: user_id).count > 0
  end

end
