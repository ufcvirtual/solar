class ExamQuestion < ActiveRecord::Base

  belongs_to :exam
  belongs_to :question

  accepts_nested_attributes_for :question

  validates :score, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0.5, allow_blank: false, less_than_or_equal_to: 10 }

  before_create :set_order

  before_destroy :can_reorder?, :unpublish

  after_save :recalculate_grades, if: 'annulled_changed?'
  
  def self.copy(exam_question_to_copy, user_id = nil)
    question = Question.copy(exam_question_to_copy.question, user_id)
    exam_question = ExamQuestion.create exam_question_to_copy.attributes.except('id', 'question_id').merge({ question_id: question.id })
    exam_question_to_copy.update_attributes annulled: true
    exam_question
  end

  def self.list(exam_id, raffle_order = false)
    query_order = []
    query_order << (raffle_order ? "RANDOM()" : "exam_questions.order")

  	ExamQuestion.joins(:question)
      .where(exam_questions: {exam_id: exam_id, annulled: false},
      	questions: {status: true})
      .select('exam_questions.question_id, exam_questions.score, exam_questions.order,
      	questions.id, questions.enunciation, questions.type_question')
      .order(query_order);
  end

  def set_order
    if order.nil?
      self.order = exam.next_question_order 
    else
      self.order += 1 while exam.exam_questions.where(order: self.order).any?
    end
  end

  def can_reorder?
    raise 'already_started' if exam.status && exam.on_going?
  end

  def recalculate_grades
    # chamar metodo de calculo de notas para todos os que existem
  end

  def can_change_annulled?
    raise 'cant_undo'    if annulled
    raise 'has_to_start' unless (exam.status && exam.started?)
  end

  def log_description
    desc = {}

    desc.merge!(question.attributes.except('attachment_updated_at', 'updated_at', 'created_at'))
    desc.merge!(exam_id: exam.id)
    desc.merge!(attributes.except('attachment_updated_at', 'updated_at', 'created_at'))
    desc.merge!(images: question.question_images.collect{|img| img.attributes.except('image_updated_at' 'question_id')})
    desc.merge!(items: question.question_items.collect{|item| item.attributes.except('question_id', 'item_image_updated_at')})
    desc.merge!(labels: question.question_labels.collect{|label| label.attributes.except('created_at', 'updated_at')})
  end

  def unpublish
    exam.update_attributes status: false
  end

end
