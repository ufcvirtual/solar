class Message < ActiveRecord::Base
  has_many :files, class_name: "MessageFile"
  has_many :user_messages

  has_many :users, through: :user_messages, uniq: true
  has_many :user_message_labels, through: :user_messages, uniq: true
  has_many :message_labels, through: :user_message_labels, uniq: true

  # box = [inbox, outbox, trashbox]
  def was_read?(user_id, box)
    return true if box == "outbox"
    user_messages.where(user_id: user_id).where("cast(user_messages.status & #{Message_Filter_Read} as boolean)").uniq.count > 0
  end

  def label(user_id)
    MessageLabel.joins(user_message_labels: :user_message).where(user_messages: {message_id: id, user_id: user_id}).uniq.first.try(:title)
  end

  def has_attachment?
    (files.count > 0)
  end

  def sent_by
    user_messages.where("cast(user_messages.status & #{Message_Filter_Sender} as boolean)").first.user
  end

  def self.user_inbox(user_id, only_unread = false)
    query = ["NOT cast(user_messages.status & #{Message_Filter_Sender + Message_Filter_Trash} as boolean)"] # NOT (sender, trash)
    query << "NOT cast(user_messages.status & #{Message_Filter_Read} as boolean)" if only_unread

    joins(:user_messages).where(user_messages: {user_id: user_id}).where(query.join(" AND ")).uniq
  end

  def self.user_outbox(user_id)
    joins(:user_messages).where(user_messages: {user_id: user_id})
      .where("cast(user_messages.status & #{Message_Filter_Sender} as boolean)").uniq  # IN (sender)
  end

  def self.user_trashbox(user_id)
    joins(:user_messages).where(user_messages: {user_id: user_id})
      .where("cast(user_messages.status & #{Message_Filter_Trash} as boolean)").uniq # IN (trash)
  end
end
