class Assignment < Event
  include AcademicTool
  include FilesHelper
  include EvaluativeTool

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :allocations, through: :allocation_tags
  has_many :enunciation_files, class_name: 'AssignmentEnunciationFile', dependent: :destroy
  has_many :group_assignments, through: :academic_allocations, dependent: :destroy
  
  before_destroy :can_destroy?
 
  validates :start_hour, presence: true, if: lambda { |c| c[:start_hour].blank?  && !c[:end_hour].blank? }
  validates :end_hour  , presence: true, if: lambda { |c| !c[:start_hour].blank? && c[:end_hour].blank?  }
  validate :check_hour, if: lambda { |c| !c[:start_hour].blank? && !c[:end_hour].blank?  }

  before_validation proc { self.schedule.check_end_date = true }, if: 'schedule' # data final obrigatoria

  accepts_nested_attributes_for :schedule 
  accepts_nested_attributes_for :enunciation_files, allow_destroy: true, reject_if: proc { |attributes| !attributes.include?(:attachment) || attributes[:attachment] == '0' || attributes[:attachment].blank? }

  validates :name, :enunciation, :type_assignment, presence: true
  validates :name, length: { maximum: 1024 }

  validate :verify_date, on: :update, if: 'type_assignment_changed?'

  after_save :update_groups, on: :update, if: 'type_assignment_changed?'

  def copy_dependencies_from(assignment_to_copy)
    unless assignment_to_copy.enunciation_files.empty?
      assignment_to_copy.enunciation_files.each do |file|
        new_file = AssignmentEnunciationFile.create! file.attributes.merge({ assignment_id: self.id })
        copy_file(file, new_file, File.join('assignment', 'enunciation'))
      end
    end
  end

  def update_groups
    if type_assignment == Assignment_Type_Individual
      academic_allocations.each do |ac|
        ac.group_to_individual
      end
    else
      academic_allocations.each do |ac|
        ac.individual_to_group
      end
    end
  end

  def can_destroy?
    academic_allocations.map(&:academic_allocation_users).flatten.empty?
  end

  def will_open?(allocation_tag_id, user_id)
    AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(user_id) && schedule.start_date.to_date > Date.today
  end

  def extra_time?(allocation_tag, user_id)
    return false unless (allocation_tag.is_observer_or_responsible?(user_id) && closed?)

    allocation_tag.offers.first.end_date.to_date >= Date.today
  end

  def in_time?(allocation_tag_id = nil, user_id = nil)
    (verify_date_range(schedule.start_date, schedule.end_date, Date.today) || (!user_id.nil? && !allocation_tag_id.nil? && (extra_time?(AllocationTag.find(allocation_tag_id), user_id))))
  end

  def verify_date_range(start_date, end_date, date)
    on_going?
    #(date >= start_date.to_date && date <= end_date.to_date)
  end

  def info(user_id, allocation_tag_id, group_id = nil)
    academic_allocation = academic_allocations.where(allocation_tag_id: allocation_tag_id).first
    return unless academic_allocation

    params =  if self.type_assignment == Assignment_Type_Group
                group_id = GroupAssignment.joins(:group_participants).where(group_participants: { user_id: user_id }, group_assignments: { academic_allocation_id: academic_allocation.id }).first.try(:id) if group_id.nil?
                { group_assignment_id: group_id }
              else
                { user_id: user_id }
              end
       
    info = academic_allocation.academic_allocation_users.where(params).first.try(:info) || { has_files: false, file_sent_date: ' - ' }

   { situation: situation(info[:has_files], !group_id.nil?, info[:grade]), has_comments: (!info[:comments].nil? && info[:comments].any?), group_id: group_id }.merge(info)

  end

  def situation(has_files, has_group, grade = nil)
    case
    when !started?                                                     then 'not_started'
    when (self.type_assignment == Assignment_Type_Group && !has_group) then 'without_group'
    when !grade.nil?                                                   then 'corrected'
    when has_files                                                     then 'sent'
    when on_going?                                                     then 'to_be_sent'
    when closed?                                                       then 'not_sent'
    else
      '-'
    end
  end

  def students_without_groups(allocation_tag_id)
    User.joins(allocations: [:profile, allocation_tag: :academic_allocations])
        .where("cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
        .where(allocations: { status: Allocation_Activated, allocation_tag_id: allocation_tag_id })
        .where(academic_allocations: { allocation_tag_id: allocation_tag_id, academic_tool_id: id, academic_tool_type: "Assignment" })
        .where('NOT EXISTS (
              SELECT * FROM group_participants
              JOIN  group_assignments ON group_participants.group_assignment_id = group_assignments.id
              WHERE group_assignments.academic_allocation_id = academic_allocations.id
                AND group_participants.user_id = users.id
            )')
        .uniq
  end

  def self.list_assigment(user_id, at_id, evaluative=false, frequency=false)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)
    wq = "academic_allocations.evaluative=true AND " if evaluative
    wq = "academic_allocations.frequency=true AND " if frequency
    wq = "academic_allocations.evaluative=false AND academic_allocations.frequency=false AND " if !evaluative && !frequency

    assignments  = Assignment.joins(:academic_allocations, :schedule)
                 .joins("LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id ")
                 .joins("LEFT JOIN group_assignments ga ON ga.academic_allocation_id = academic_allocations.id AND academic_allocations.academic_tool_type = 'Assignment'")
                 .joins("LEFT JOIN group_participants gp ON ga.id = gp.group_assignment_id AND (academic_allocation_users.id=#{user_id} OR gp.user_id=#{user_id})")
                 .joins("LEFT JOIN assignment_files ON assignment_files.academic_allocation_user_id = academic_allocation_users.id ")
                 .joins("LEFT JOIN assignment_webconferences ON assignment_webconferences.academic_allocation_user_id = academic_allocation_users.id")
                 .where(wq + "academic_allocations.allocation_tag_id= ?",  at.id )
                 .select("DISTINCT assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date, academic_allocation_users.grade, academic_allocation_users.working_hours, 
                          case
                            when (current_date < schedules.start_date AND (assignments.start_hour IS NULL OR assignments.start_hour = '')) OR  (current_date <= schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.end_hour != '' AND current_time<to_timestamp(assignments.start_hour, 'HH24:MI:SS')::time)) then 'not_started'
                            when assignments.type_assignment = 1 AND ga.id IS NULL         then 'without_group'
                            when grade IS NOT NULL                                         then 'corrected'
                            when attachment_updated_at IS NOT NULL OR (is_recorded AND (initial_time + (interval '1 mins')*duration) < now())  then 'sent'
                            when (current_date <= schedules.end_date AND (assignments.end_hour IS NULL OR assignments.end_hour = '')) OR (current_date <= schedules.end_date AND (assignments.end_hour IS NOT NULL AND assignments.end_hour != '' AND current_time<=to_timestamp(assignments.end_hour, 'HH24:MI:SS')::time))                          then 'to_be_sent'
                            when schedules.end_date < current_date                           then 'not_sent'
                            else  '-'
                          end AS status")
                 .order("start_date") if at.is_student?(user_id)
  end  

   def closed?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    endt      = (has_hours ? (schedule.end_date.beginning_of_day + end_hour.split(':')[0].to_i.hours + end_hour.split(':')[1].to_i.minutes) : schedule.end_date.end_of_day)
    Time.now > endt
  end

  def started?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    startt    = (has_hours ? (schedule.start_date.beginning_of_day + start_hour.split(':')[0].to_i.hours + start_hour.split(':')[1].to_i.minutes) : schedule.start_date.beginning_of_day)
    Time.now >= startt
  end

  def on_going?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    startt    = (has_hours ? (schedule.start_date.beginning_of_day + start_hour.split(':')[0].to_i.hours + start_hour.split(':')[1].to_i.minutes) : schedule.start_date.beginning_of_day)
    endt      = (has_hours ? (schedule.end_date.beginning_of_day + end_hour.split(':')[0].to_i.hours + end_hour.split(':')[1].to_i.minutes) : schedule.end_date.end_of_day)
    Time.now.between?(startt,endt)
  end

  def on_going_changed?
    has_hours = (!start_hour_was.blank? && !start_hour_was.blank?)
    startt    = (has_hours ? (schedule.start_date_was.beginning_of_day + start_hour_was.split(':')[0].to_i.hours + start_hour_was.split(':')[1].to_i.minutes) : schedule.start_date_was.beginning_of_day)
    endt      = (has_hours ? (schedule.end_date_was.beginning_of_day + end_hour_was.split(':')[0].to_i.hours + end_hour_was.split(':')[1].to_i.minutes) : schedule.end_date_was.end_of_day)
    Time.now.between?(startt,endt)
  end

  def check_hour
    errors.add(:start_hour, I18n.t('exams.error.same_day')) if schedule.start_date != schedule.end_date
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if (end_hour.rjust(5, '0') < start_hour.rjust(5, '0'))
  end

  def def_hour
    if (schedule.start_date_changed? || schedule.end_date_changed?) && schedule.start_date_changed? != schedule.end_date_changed?
      self.start_hour = nil
      self.end_hour = nil
    end
  end

  def verify_date
    errors.add(:type_assignment, I18n.t('assignments.error.change_type_after_period')) if closed?
  end

  def assignment_started?(allocation_tag_id, current_user)
    raise "not_started_up" unless started? || AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(current_user.id)
  end

  def groups_assignments(allocation_tag_id)
    GroupAssignment.joins(:academic_allocation).where(academic_allocations: {academic_tool_id: self.id, allocation_tag_id: allocation_tag_id})
  end

  def self.owned_by_user?(user_id, options={})
    assignment_user_id = (options[:academic_allocation_user].try(:user_id)          || options[:student_id])
    group              = (options[:academic_allocation_user].try(:group_assignment) || options[:group])

    ((assignment_user_id.to_i == user_id.to_i) || (!group.nil? && group.user_in_group?(user_id.to_i)) )
  end

  def self.verify_previous(acu_id)
    AssignmentFile.where(academic_allocation_user_id: acu_id).any? || AssignmentWebconference.where(academic_allocation_user_id: acu_id, final: true).any?
  end

  def self.update_previous(ac_id, users_ids, acu_id)
    return false
  end

end
