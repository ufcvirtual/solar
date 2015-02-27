class SentAssignment < ActiveRecord::Base

  belongs_to :user
  belongs_to :group_assignment

  #Associação polimórfica
  belongs_to :academic_allocation, conditions: {academic_tool_type: 'Assignment'}
  has_one :assignment, through: :academic_allocation
  #Associação polimórfica

  has_many :assignment_comments, dependent: :destroy
  has_many :assignment_files, dependent: :delete_all

  validates :user_id, uniqueness: { scope: [:group_assignment_id, :academic_allocation_id] }

  before_save :if_group_assignment_remove_user_id
  before_save :has_group, if: Proc.new {|a| a.assignment.type_assignment == Assignment_Type_Group }

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true}

  def if_group_assignment_remove_user_id
    self.user_id = nil if group_assignment_id
  end

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

  def info
    grade, comments, files = try(:grade), try(:assignment_comments), try(:assignment_files)
    has_files = (not(files.nil?) and files.any?)
    {grade: grade, comments: comments, has_files: has_files, file_sent_date: (has_files ? I18n.l(files.first.attachment_updated_at, format: :normal) : " - ")}
  end

  def delete_with_dependents
    assignment_comments.map(&:delete_with_dependents)
    assignment_files.delete_all
    self.delete
  end

  def has_group
    not(group_assignment_id.nil?)
  end

end
