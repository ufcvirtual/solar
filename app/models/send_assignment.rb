class SendAssignment < ActiveRecord::Base

  belongs_to :assignment

  has_many :assignment_comments
  has_many :files_sends

end
