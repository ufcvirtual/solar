class ScheduleEvent < Event
  include AcademicTool
  include EvaluativeTool

  COURSE_PERMISSION = CURRICULUM_UNIT_PERMISSION = GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :schedule

  validates :title, :type_event, presence: true
  validates :start_hour, :end_hour, :place, presence: true, if:  Proc.new{|event| [Presential_Test, WebConferenceLesson, Presential_Meeting].include?(event.type_event)}
  validates_format_of :start_hour, :end_hour, with: /\A([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/, if:  Proc.new{|event| [Presential_Test, WebConferenceLesson, Presential_Meeting].include?(event.type_event)}

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank?}, if:  Proc.new{|event| [Presential_Test, WebConferenceLesson, Presential_Meeting].include?(event.type_event)}

  accepts_nested_attributes_for :schedule

  before_destroy :can_remove_groups_with_raise

  attr_accessor :api

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
      when Other; :other
    end

    I18n.t(te, scope: "schedule_events.types")
  end

  def self.type_name_event(type_event)
    te = case type_event
      when Presential_Meeting; :presential_meeting
      when Presential_Test; :presential_test
      when WebConferenceLesson; :webconference_lesson
      when Recess; :recess
      when Holiday; :holiday
      when Other; :other
    end

    I18n.t(te, scope: "schedule_events.types")
  end

  def info(user_id, allocation_tag_id)
    academic_allocation = academic_allocations.where(allocation_tag_id: allocation_tag_id).first
    return unless academic_allocation

    params = { user_id: user_id }
    acu = academic_allocation.academic_allocation_users.where(params).first
    info = acu.try(:info) || { has_files: false, file_sent_date: ' - ' }

    comments = (!info[:comments].nil? && info[:comments].any?)
    { situation: situation(info[:has_files], info[:grade], info[:working_hours], comments), has_comments: comments, ac_id: academic_allocation.id }.merge(info)
  end

  def situation(has_files, grade = nil, working_hours = nil, has_comments=[])
    case
    when !started? then 'not_started'
    when !grade.blank? || !working_hours.blank? || has_comments then 'corrected'
    when has_files then 'sent'
    when on_going? then 'to_be_sent'
    when ended? then 'not_sent'
    else
      '-'
    end
  end

  def on_going?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    startt    = (has_hours ? (schedule.start_date.beginning_of_day + start_hour.split(':')[0].to_i.hours + start_hour.split(':')[1].to_i.minutes) : schedule.start_date.beginning_of_day)
    endt      = (has_hours ? (schedule.end_date.beginning_of_day + end_hour.split(':')[0].to_i.hours + end_hour.split(':')[1].to_i.minutes) : schedule.end_date.end_of_day)
    Time.now.between?(startt,endt)
  end

  def ended?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    endt      = (has_hours ? (schedule.end_date.beginning_of_day + end_hour.split(':')[0].to_i.hours + end_hour.split(':')[1].to_i.minutes) : schedule.end_date.end_of_day)
    Time.now > endt
  end

  def can_change?
    api || new_record? || !integrated
  end

  def self.verify_previous(acu_id)
    return false
  end

  def self.update_previous(ac_id, user_id, acu_id)
    return true
  end

  def started?
    DateTime.new(schedule.start_date.year, schedule.start_date.month, schedule.start_date.day, (start_hour.blank? ? 0 : start_hour.split(':').first.to_i), (start_hour.blank? ? 0 : start_hour.split(':').last.to_i)) <= DateTime.now
  end

  def self.list_schedule_event(allocation_tag_id, evaluative=false, frequency=false)
    wq = "academic_allocations.evaluative=true " if evaluative
    wq = "academic_allocations.frequency=true " if frequency
    wq = "academic_allocations.evaluative=false AND academic_allocations.frequency=false " if !evaluative && !frequency

    joins(:schedule, academic_allocations: :allocation_tag)
    .joins('LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id')
    .where(allocation_tags: { id: AllocationTag.find(allocation_tag_id).related })
    .where(wq)
    .select("schedule_events.*, academic_allocations.id AS ac_id, schedules.start_date AS start_date, schedules.end_date AS end_date, CASE WHEN current_date>schedules.end_date OR current_date=schedules.end_date AND current_time>cast(end_hour as time) THEN 'closed'
       WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND start_hour IS NULL THEN 'started'
       WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND current_time>=cast(start_hour as time) AND current_time<=cast(end_hour as time) THEN 'started'
       ELSE 'not_started'  END AS status")
    .group('schedule_events.id, schedules.start_date, schedules.end_date, title , academic_allocations.id')
    .order('start_date, end_date, title ')

  end

  def self.get_all_events allocation_tags_ids
    joins(:schedule, academic_allocations: :allocation_tag)
    .where(allocation_tags: { id: allocation_tags_ids })
    .select("schedule_events.*, academic_allocations.id AS ac_id, schedules.start_date AS start_date, schedules.end_date AS end_date, CASE WHEN current_date>schedules.end_date OR current_date=schedules.end_date AND current_time>cast(end_hour as time) THEN 'closed'
       WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND start_hour IS NULL THEN 'started'
       WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND current_time>=cast(start_hour as time) AND current_time<=cast(end_hour as time) THEN 'started'
       ELSE 'not_started'  END AS status")
    .group('schedule_events.id, schedules.start_date, schedules.end_date, title , academic_allocations.id')
    .order('start_date, end_date, title ')
  end

end
