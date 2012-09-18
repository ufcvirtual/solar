class AssignmentComment < ActiveRecord::Base

  belongs_to :send_assignment
  belongs_to :user
  has_many :comment_files, :dependent => :destroy

  validates :comment, :presence => true

	default_scope :order => 'updated_at DESC'

end
