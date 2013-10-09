class AssignmentComment < ActiveRecord::Base
  default_scope order: 'updated_at DESC'

  belongs_to :sent_assignment
  belongs_to :user

  has_many :comment_files, dependent: :destroy

  validates :comment, presence: true
end
