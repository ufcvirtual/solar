class Assignment < ActiveRecord::Base

  belongs_to :allocation_tag

  has_many :files_enunciations
  has_many :send_assignments

end
