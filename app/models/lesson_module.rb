class LessonModule < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  #Associação polimórfica
  has_many :academic_allocations, as: :academic_tool , dependent: :destroy
  #Associação polimórfica

  has_many :lessons, dependent: :destroy
  
  #Relações extras
  has_many :allocation_tags, through: :academic_allocations
  #EXTRAS

  validates :name, presence: true
 
end
