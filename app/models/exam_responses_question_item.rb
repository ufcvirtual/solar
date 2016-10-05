class ExamResponsesQuestionItem < ActiveRecord::Base
  belongs_to :exam_response
  belongs_to :question_item

  validates_uniqueness_of :exam_response_id, scope: [:question_item_id]

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
    question_item.item_image
  end

  def img_alt
    question_item.img_alt
  end
end