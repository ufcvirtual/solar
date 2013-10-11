class LessonModule < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  has_many :academic_allocations, as: :academic_tool #, dependent: :delete_all
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  has_many :lessons

  before_destroy :move_lessons_to_default

  validates :name, presence: true
  validate :unique_name

  def unique_name
  	unless name.nil?
  		modules_with_same_name = LessonModule.first(:conditions => ["allocation_tag_id = ? AND lower(name) = ?", allocation_tag_id, name.downcase])
    	errors.add(:name, I18n.t(:existing_name, :scope => [:lesson_modules, :errors])) if (@new_record == true or name_changed?) and (not modules_with_same_name.nil?)
    end
  end

  private

    def move_lessons_to_default
      if is_default
        errors.add(:base, I18n.t(:cant_delete, :scope => [:lesson_modules, :errors]))
        return false
      else
        lessons.update_all(lesson_module_id: LessonModule.where(is_default: true, allocation_tag_id: allocation_tag))
      end
    end

end
