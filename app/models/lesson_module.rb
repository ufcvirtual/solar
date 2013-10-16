class LessonModule < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations

  has_many :lessons, dependent: :destroy
  
  validates :name, presence: true

  before_destroy :delete_academic_allocations

  def delete_academic_allocations
    if lessons.empty?
      AcademicAllocation.where(academic_tool_id: id, academic_tool_type: 'LessonModule').each do |aalm|
        aalm.delete
      end
    end    
  end  
 
end
