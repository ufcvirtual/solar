class ChatRoom < ActiveRecord::Base
  
  GROUP_PERMISSION = true

  has_many :messages, class_name: "ChatMessage", dependent: :destroy
  has_many :participants, class_name: "ChatParticipant", dependent: :destroy
  has_many :academic_allocations, as: :academic_tool
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  has_many :users, through: :participants
  has_many :allocations, through: :participants

  belongs_to :schedule

  accepts_nested_attributes_for :schedule

  validates :title, :start_hour, :end_hour, presence: true

  validates_format_of :start_hour, :end_hour, with: /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank?}

  accepts_nested_attributes_for :participants, allow_destroy: true, reject_if: proc { |attributes| attributes['allocation_id'] == "0" }

  attr_accessible :participants_attributes, :title, :start_hour, :end_hour, :description, :schedule_attributes, :chat_type

  after_destroy :delete_schedule

  def verify_hours
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if end_hour.rjust(5, '0') < start_hour.rjust(5, '0')
  end

  def delete_schedule
    self.schedule.destroy
  end

end
