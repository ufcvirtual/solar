class ScheduleEvent < Event

  COURSE_PERMISSION, CURRICULUM_UNIT_PERMISSION, GROUP_PERMISSION, OFFER_PERMISSION = true, true, true, true

  belongs_to :schedule

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  validates :title, :type_event, presence: true

  validates :start_hour, :end_hour, :place, presence: true, if:  Proc.new{|event| event.type_event == Presential_Test or event.type_event == Presential_Meeting} 
  validates_format_of :start_hour, :end_hour, with: /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/, if:  Proc.new{|event| event.type_event == Presential_Test or event.type_event == Presential_Meeting} 
  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank?}, if:  Proc.new{|event| event.type_event == Presential_Test or event.type_event == Presential_Meeting} 

  accepts_nested_attributes_for :schedule

  attr_accessible :title, :description, :schedule_attributes, :schedule_id, :type_event, :start_hour, :end_hour, :place

  def verify_hours
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:schedule_events, :error])) if end_hour.rjust(5, '0') < start_hour.rjust(5, '0')
  end

end
