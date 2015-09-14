class SentAssignment < ActiveRecord::Base

  belongs_to :user
  belongs_to :group_assignment
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Assignment' }

  has_one :assignment,     through: :academic_allocation
  has_one :allocation_tag, through: :academic_allocation  

  has_many :assignment_comments,       dependent: :destroy
  has_many :assignment_files,          dependent: :delete_all
  has_many :assignment_webconferences, dependent: :delete_all

  validates :user_id, uniqueness: { scope: [:group_assignment_id, :academic_allocation_id] }

  before_save :if_group_assignment_remove_user_id
  before_save :has_group, if: Proc.new { |a| a.assignment.type_assignment == Assignment_Type_Group }

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true }
  validate :verify_student, only: :create, if: 'merge.nil?'

  attr_accessor :can_create, :merge

  def if_group_assignment_remove_user_id
    self.user_id = nil if group_assignment_id
  end

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

  def info
    grade, comments = try(:grade), try(:assignment_comments)
    
    files = SentAssignment.find_by_sql <<-SQL
      SELECT MAX(max_date) FROM (
        SELECT MAX(initial_time) AS max_date FROM assignment_webconferences 
        WHERE sent_assignment_id = #{id}
        AND is_recorded = 't'
        AND (initial_time + (interval '1 minutes')*duration) < now()

        UNION

        SELECT MAX(attachment_updated_at) AS max_date FROM assignment_files 
        WHERE attachment_updated_at IS NOT NULL 
        AND sent_assignment_id = #{id}
      ) AS max;

    SQL

    has_files = !files.first.max.nil?
    { grade: grade, comments: comments, has_files: has_files, file_sent_date: (has_files ? I18n.l(files.first.max.to_datetime, format: :normal) : ' - ') }
  end

  def delete_with_dependents
    assignment_comments.map(&:delete_with_dependents)
    assignment_files.delete_all
    assignment_webconferences.delete_all
    self.delete
  end

  def has_group
    !group_assignment_id.nil?
  end

  def users_count
    has_group ? group_assignment.group_participants.count : 1
  end

  def verify_student
    errors.add(:base, 'cant_create_sent_assignment') unless can_create || User.current.has_profile_type_at(allocation_tag.id)
  end

end
