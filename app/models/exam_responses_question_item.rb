class ExamResponsesQuestionItem < ActiveRecord::Base
  belongs_to :exam_response
  belongs_to :question_item

  default_scope { order(:id) }

  before_save :set_all_unique, on: :update

  validates_uniqueness_of :exam_response_id, scope: [:question_item_id]

  def order
    'id'
   end 

  def comment
    question_item.comment
  end

  def description
    question_item.description
  end

  def item_image?
    question_item.item_image?
  end

  def item_image
    question_item.item_image(:medium)
  end

  def img_alt
    question_item.img_alt
  end

  def item_audio?
    question_item.item_audio?
  end

  def item_audio
    question_item.item_audio
  end

  def audio_description
    question_item.audio_description
  end

  def audio_description?
    question_item.audio_description?
  end

  def set_all_unique
    question = Question.find(question_item.question_id)
    unless self.exam_response_id.nil?
      if question.type_question == Question::UNIQUE 
        ExamResponsesQuestionItem.where(exam_response_id: exam_response_id, value: true).update_all(value: false)
      end
    end
  end
end
