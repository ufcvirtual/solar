class QuestionLabelsQuestion < ActiveRecord::Base
  belongs_to :questions
  belongs_to :question_labels
  validates_uniqueness_of :question_label_id, scope: :question_id
end