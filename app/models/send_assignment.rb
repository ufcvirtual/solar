class SendAssignment < ActiveRecord::Base

  belongs_to :assignment

  has_many :assignment_comments
  has_many :assignment_files

  # validate se tiver user_id, não precisa de group. e vice-versa.

end
