class LessonModule < ActiveRecord::Base
  belongs_to :allocation_tag
  has_many :lessons

  validates :name, :presence => true

  validate :unique_name

  def unique_name
    modules_with_same_name = LessonModule.find_all_by_allocation_tag_id_and_name(allocation_tag_id, name)
    errors.add(:name, I18n.t(:existing_name, :scope => [:lesson_modules, :errors])) if (@new_record == true or name_changed?) and modules_with_same_name.size > 0
  end
end