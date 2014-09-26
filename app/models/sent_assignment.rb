class SentAssignment < ActiveRecord::Base

  belongs_to :user
  belongs_to :group_assignment

  #Associação polimórfica
  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Assignment'}
  has_one :assignment, through: :academic_allocation
  #Associação polimórfica

  has_many :assignment_comments, dependent: :destroy
  has_many :assignment_files, dependent: :destroy

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true}

  before_save :if_group_assignment_remove_user_id

  def if_group_assignment_remove_user_id
    self.user_id = nil if group_assignment_id
  end

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

end
