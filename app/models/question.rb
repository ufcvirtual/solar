class Question < ActiveRecord::Base
  belongs_to  :user

  has_many :exam_questions
  has_many :question_images, dependent: :destroy
  has_many :question_items, dependent: :destroy

  has_and_belongs_to_many :question_labels
  before_destroy { question_labels.clear }
end
