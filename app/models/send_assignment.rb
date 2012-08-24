class SendAssignment < ActiveRecord::Base

  belongs_to :user
  belongs_to :assignment
  belongs_to :group_assignment

  has_many :assignment_comments
  has_many :assignment_files

  validates :grade, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10, :allow_blank => true}

end
