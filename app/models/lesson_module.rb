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
   if lessons.count > 0  and academic_allocations.count > 1
     errors.add(:base, I18n.t(:cant_delete_shared, :scope => [:lesson_modules, :errors]))
     return false
   elsif is_default
     errors.add(:base, I18n.t(:cant_delete, :scope => [:lesson_modules, :errors]))
     return false
   end
  end

  def self.to_select(allocation_tags_ids, user = nil, list = false)
    user_is_admin    = user.nil? ? false : user.is_admin?
    user_responsible = user.nil? ? false : AllocationTag.find(allocation_tags_ids).compact.map{|at| at.is_user_class_responsible?(user.id) }.include?(true)
    joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: allocation_tags_ids}).order("name").delete_if{ |lmodule|
      lessons               = lmodule.lessons
      has_visible_lesson    = (list or lessons.map(&:open_to_show?).include?(true)) # if list is true, it must show closed lessons
      only_has_draft_lesson = not(lessons.map(&:is_draft?).include?(false))
      has_lessons_to_open   = (list or lessons.map(&:will_open?).include?(true)) # if list is true, it must show lessons which will open
      lessons.empty? or not( user_is_admin or (user_responsible and (only_has_draft_lesson or has_lessons_to_open)) or ( not(only_has_draft_lesson) and has_visible_lesson ) )
    }.compact.uniq
  end

  def lessons_to_open(user = nil, list = false)
    user_is_admin    = user.is_admin?
    user_responsible = allocation_tags.map{|at| at.is_user_class_responsible?(user.id) }.include?(true) unless user.nil?
    lessons.order("lessons.order").collect{ |lesson|
      # if (lesson can open to show or list is true) or (is draft or will_open and is responsible) or user is admin 
      lesson if ( user_is_admin or (user_responsible and (lesson.is_draft? or lesson.will_open?) ) or (not(lesson.is_draft?) and ((list and not(lesson.will_open?)) or lesson.open_to_show?)) )
    }.compact.uniq
  end
 
end
