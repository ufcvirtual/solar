class LessonNote < ActiveRecord::Base

  belongs_to :lesson
  belongs_to :user

  validates :description, :lesson_id, :user_id, presence: true

  # validates :name # máximo de 50 e deve ser único com  olesson_id e user_id

  # attr_accessible :title, :body

end
