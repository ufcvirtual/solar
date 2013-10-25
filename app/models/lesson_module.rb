class LessonModule < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true
  
  # A ordem das instruções importa para execução
  before_destroy :verify_situation_module

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations

  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  has_many :lessons, dependent: :destroy
  
  validates :name, presence: true
  
  def verify_situation_module 
   if lessons.count > 0  and  academic_allocations.count > 1
     errors.add(:base, I18n.t(:cant_delete_shared, :scope => [:lesson_modules, :errors]))
     return false
   elsif is_default
     errors.add(:base, I18n.t(:cant_delete, :scope => [:lesson_modules, :errors]))
     return false
   end 
  end    
 
end
