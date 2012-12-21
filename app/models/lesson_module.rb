class LessonModule < ActiveRecord::Base
  belongs_to :allocation_tag
  has_many :lessons, :dependent => :destroy

  validates :name, :presence => true
  validate :unique_name

  # valida se o nome é único para uma mesma allocation_tag_id
  def unique_name
  	modules_with_same_name = LessonModule.first(:conditions => ["allocation_tag_id = ? AND lower(name) = ?", allocation_tag_id, name.downcase])
    errors.add(:name, I18n.t(:existing_name, :scope => [:lesson_modules, :errors])) if (@new_record == true or name_changed?) and (not modules_with_same_name.nil?)
  end
end