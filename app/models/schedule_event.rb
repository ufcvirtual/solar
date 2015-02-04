class ScheduleEvent < Event
  include AcademicTool

  COURSE_PERMISSION = CURRICULUM_UNIT_PERMISSION = GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :schedule

  validates :title, :type_event, presence: true
  validates :start_hour, :end_hour, :place, presence: true, if:  Proc.new{|event| [Presential_Test, WebConferenceLesson, Presential_Meeting].include?(event.type_event)}
  validates_format_of :start_hour, :end_hour, with: /\A([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/, if:  Proc.new{|event| [Presential_Test, WebConferenceLesson, Presential_Meeting].include?(event.type_event)}

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank?}, if:  Proc.new{|event| [Presential_Test, WebConferenceLesson, Presential_Meeting].include?(event.type_event)}

  accepts_nested_attributes_for :schedule

  def verify_hours
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:schedule_events, :error])) if end_hour.rjust(5, '0') < start_hour.rjust(5, '0')
  end

  def type_name
    te = case type_event
      when Presential_Meeting; :presential_meeting
      when Presential_Test; :presential_test
      when WebConferenceLesson; :webconference_lesson
      when Recess; :recess
      when Holiday; :holiday
    end

    I18n.t(te, scope: "schedule_events.types")
  end

  def can_change?
    new_record? or not(integrated)
  end

end
