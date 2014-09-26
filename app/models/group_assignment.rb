class GroupAssignment < ActiveRecord::Base

  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Assignment'}

  has_one :sent_assignment, dependent: :destroy

  has_many :group_participants, dependent: :destroy
  has_many :users, through: :group_participants

  validates :group_name, presence: true, length: { maximum: 20 }
  validate :unique_group_name
 
  def can_remove?
    (sent_assignment.nil? or (sent_assignment.assignment_files.empty? and sent_assignment.grade.blank?))
  end

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

  def evaluated?
    not(sent_assignment.nil? or sent_assignment.grade.blank?)
  end

  def user_in_group?(user_id)
    group_participants.map(&:user_id).include? user_id.to_i
  end

  private

    def unique_group_name
      groups_with_same_name = GroupAssignment.find_all_by_academic_allocation_id_and_group_name(academic_allocation_id, group_name)
      errors.add(:group_name, I18n.t(:existing_name_error, :scope => [:assignment, :group_assignments])) if (@new_record == true or group_name_changed?) and groups_with_same_name.size > 0
    end

end
