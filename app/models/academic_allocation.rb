class AcademicAllocation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag


  #Relacionamentos extras#
  has_many :sent_assignments
end
