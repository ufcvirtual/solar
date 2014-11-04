class GroupAssignment < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  before_destroy :can_destroy? # deve ficar antes das associacoes

  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Assignment'}

  has_one :sent_assignment, dependent: :destroy

  has_many :group_participants, dependent: :delete_all
  has_many :users, through: :group_participants

  validates :group_name, presence: true, length: { maximum: 20 }

  validate :define_name
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

  def can_destroy?
    raise "cant_remove" unless can_remove?
  end

  def copy(to_ac_id)
    new_group = GroupAssignment.where(group_name: group_name, academic_allocation_id: to_ac_id).first_or_create!
    copy_participants(new_group.id, to_ac_id)
  end

  def copy_participants(group_id, ac_id)
    all_participants = GroupAssignment.where(academic_allocation_id: ac_id).map(&:users).flatten.map(&:id)
    group_participants.each do |participant|
      GroupParticipant.where(user_id: participant.user_id, group_assignment_id: group_id).first_or_create! unless all_participants.include? participant.user_id
    end
  end

  def delete_with_dependents
    group_participants.delete_all
    self.delete
  end

  def self.by_user_id(user_id, academic_allocation_id)
    joins(:group_participants).where(academic_allocation_id: academic_allocation_id, group_participants: {user_id: user_id}).first
  end

  private

    def unique_group_name
      groups_with_same_name = GroupAssignment.find_all_by_academic_allocation_id_and_group_name(academic_allocation_id, group_name)
      errors.add(:group_name, I18n.t("group_assignments.error.unique_name")) if (new_record? or group_name_changed?) and groups_with_same_name.size > 0
    end

    def define_name
      if group_name == I18n.t("group_assignments.new.new_group_name")
        count, group = 1, GroupAssignment.where({group_name: "#{I18n.t("group_assignments.new.new_group_name")}", academic_allocation_id: academic_allocation_id}).first_or_initialize

        until group.new_record?
          group = GroupAssignment.where({group_name: "#{I18n.t("group_assignments.new.new_group_name")} #{count}", academic_allocation_id: academic_allocation_id}).first_or_initialize
          count += 1
        end

        self.group_name = group.group_name
      end
    end

end
