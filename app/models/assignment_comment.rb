class AssignmentComment < ActiveRecord::Base
  default_scope order: 'updated_at DESC'

  belongs_to :sent_assignment
  belongs_to :user

  has_many :files, class_name: "CommentFile", dependent: :destroy

  accepts_nested_attributes_for :files, allow_destroy: true, reject_if: proc {|attributes| not attributes.include?(:attachment)}

  validates :comment, presence: true

  def assignment
  	sent_assignment.assignment
  end
end
