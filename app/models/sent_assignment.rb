class SentAssignment < ActiveRecord::Base

  belongs_to :user

  #Associação polimórfica
  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Assignment'}
  #Associação polimórfica

  belongs_to :group_assignment

  has_many :assignment_comments, dependent: :destroy
  has_many :assignment_files

  validates :grade, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10, :allow_blank => true}

  before_save :if_group_assignment_remove_user_id

  ## Em situações de trabalho em grupo avaliado a partir de links que tenham um id do aluno, remover o id do aluno no momento de salvar o sent_assignment
  def if_group_assignment_remove_user_id
    self.user_id = nil if group_assignment_id
  end

  def sent_by_group?
    not group_assignment.nil?
  end

  def user_can_access?(check_user, allocation_tag)
    return true if allocation_tag.is_user_class_responsible?(check_user) # professor
    return true if sent_by_group? and group_assignment.group_participants.map(&:user_id).include?(check_user.id) # user is part of the group
    return true if user == check_user # user that sent assignment
    return false
  end

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end
end
