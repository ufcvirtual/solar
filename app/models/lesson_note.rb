class LessonNote < ActiveRecord::Base

  belongs_to :lesson
  belongs_to :user

  validates :description, :lesson_id, :user_id, presence: true

  validates :name, length: { maximum: 50 }

  before_save :unique_name 

  def unique_name
    lesson_note = LessonNote.where(name: name, user_id: user_id, lesson_id: lesson_id)
    raise 'unique_name' if lesson_note.any? && (new_record? || name_changed?)
  end

end
