class QuestionLabelsQuestion < ActiveRecord::Base
  belongs_to :question
  belongs_to :question_label
  validates_uniqueness_of :question_label_id, scope: :question_id
end