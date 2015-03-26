class Assignment < Event
  include AcademicTool

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :allocations, through: :allocation_tags
  has_many :enunciation_files, class_name: 'AssignmentEnunciationFile', dependent: :destroy
  has_many :group_assignments, through: :academic_allocations, dependent: :destroy
  has_many :sent_assignments, through: :academic_allocations

  before_destroy :can_destroy?

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :enunciation_files, allow_destroy: true, reject_if: proc { |attributes| !attributes.include?(:attachment) }

  validates :name, :enunciation, :type_assignment, presence: true
  validates :name, length: { maximum: 1024 }

  def copy_dependencies_from(assignment_to_copy)
    AssignmentEnunciationFile.create! assignment_to_copy.enunciation_files.map { |file| file.attributes.merge({ assignment_id: self.id }) } unless assignment_to_copy.enunciation_files.empty?
  end

  def can_remove_groups?(groups)
    # não pode dar unbind nem remover se assignment possuir sent_assignment
    SentAssignment.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: self.id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
  end

  def can_destroy?
    academic_allocations.map(&:sent_assignments).flatten.empty?
  end

  def sent_assignment_by_user_id_or_group_assignment_id(allocation_tag_id, user_id, group_assignment_id)
    SentAssignment.joins(:academic_allocation).where(user_id: user_id, group_assignment_id: group_assignment_id, academic_allocations: { academic_tool_id: id, allocation_tag_id: allocation_tag_id }).first
  end

  def closed?
    schedule.end_date.to_date < Date.today
  end

  def will_open?(allocation_tag_id, user_id)
    AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(user_id) && schedule.start_date.to_date > Date.today
  end

  def extra_time?(allocation_tag, user_id)
    extra = (allocation_tag.is_observer_or_responsible?(user_id) && closed?)

    return false unless extra

    offer = case allocation_tag.refer_to
            when 'offer' then allocation_tag.offer
            when 'group' then allocation_tag.group.offer
            end

    # periodo pode estar definido na oferta ou no semestre
    period_end_date = if offer.period_schedule.nil?
                        offer.semester.offer_schedule.end_date
                      else
                        offer.period_schedule.end_date
                      end

    extra && period_end_date.to_date >= Date.today
  end

  def in_time?(allocation_tag_id, user_id = nil)
    (verify_date_range(schedule.start_date, schedule.end_date, Date.today) || (!user_id.nil? && (extra_time?(AllocationTag.find(allocation_tag_id), user_id))))
  end

  def verify_date_range(start_date, end_date, date)
    (date >= start_date.to_date && date <= end_date.to_date)
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

    info = academic_allocation.sent_assignments.where(params).first.try(:info) || { has_files: false, file_sent_date: ' - ' }
    { situation: situation(info[:has_files], !group_id.nil?, info[:grade]), has_comments: (!info[:comments].nil? && info[:comments].any?), group_id: group_id }.merge(info)
  end

  def situation(has_files, has_group, grade = nil)
    case
    when schedule.start_date.to_date > Date.current                    then 'not_started'
    when (self.type_assignment == Assignment_Type_Group && !has_group) then 'without_group'
    when !grade.nil?                                                   then 'corrected'
    when has_files                                                     then 'sent'
    when (schedule.end_date.to_date >= Date.today)                     then 'to_be_sent'
    when (schedule.end_date.to_date < Date.today)                      then 'not_sent'
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

  def groups_assignments(allocation_tag_id)
    GroupAssignment.joins(:academic_allocation).where(academic_allocations: {academic_tool_id: self.id, allocation_tag_id: allocation_tag_id})
  end

  def self.owned_by_user?(user_id, options={})
    assignment_user_id = (options[:sent_assignment].try(:user_id)          || options[:student_id])
    group              = (options[:sent_assignment].try(:group_assignment) || options[:group])

    (assignment_user_id.to_i == user_id.to_i || (!group.nil? && group.user_in_group?(user_id.to_i)) )
  end

end
