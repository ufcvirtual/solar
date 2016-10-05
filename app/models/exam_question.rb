class ExamQuestion < ActiveRecord::Base

  belongs_to :exam
  belongs_to :question

  has_many :exam_responses, through: :question
  has_many :question_items, through: :question

  accepts_nested_attributes_for :question

  validates :score, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0.5, allow_blank: false, less_than_or_equal_to: 10 }

  before_create :set_order

  before_destroy :can_reorder?, :can_save?, :unpublish

  before_save :can_save?, unless: 'annulled_changed?'
  after_save :recalculate_grades, if: 'annulled_changed? && exam.status'

  def recalculate_grades
    exam.recalculate_grades
  end

  def self.copy(exam_question_to_copy, user_id = nil)
    question = Question.copy(exam_question_to_copy.question, user_id)
    exam_question = ExamQuestion.create exam_question_to_copy.attributes.except('id', 'question_id').merge({ question_id: question.id })
    exam_question_to_copy.update_attributes annulled: true
    exam_question
  end

  def self.list(exam_id, raffle_order = false, last_attempt=nil)
    if last_attempt.blank? # preview
      exam = Exam.find(exam_id)
      query = {exam_id: exam_id, annulled: false}
      query.merge!(use_question: true, questions: {status: true}) if exam.status

      ExamQuestion.joins(:question).where(query)
        .select('exam_questions.question_id, exam_questions.score, exam_questions.order,
          questions.id, questions.enunciation, questions.type_question, exam_questions.annulled')
        .order((raffle_order ? "RANDOM()" : "exam_questions.order"))
    else
      responses = last_attempt.try(:complete) ? nil : last_attempt.try(:exam_responses)

      if responses.blank?
        exam_questions = ExamQuestion.joins(:question)
          .where(exam_questions: {exam_id: exam_id, annulled: false, use_question: true},
            questions: {status: true})
          .select('exam_questions.question_id, exam_questions.score, exam_questions.order,
            questions.id, questions.enunciation, questions.type_question, exam_questions.annulled')
          .order((raffle_order ? "RANDOM()" : "exam_questions.order"))

        exam_questions.each do |exam_question|
          response = last_attempt.exam_responses.where(question_id: exam_question.question_id).first_or_create!(duration: 0)

          response.question.question_items.pluck(:id).each do |item|
            response.exam_responses_question_items.where(question_item_id: item).first_or_create!
          end
        end
      end

      ExamQuestion.joins(:question).joins(:exam_responses)
        .where(exam_questions: {exam_id: exam_id, annulled: false, use_question: true},
          exam_responses: {exam_user_attempt_id: last_attempt.id},
          questions: {status: true})
        .select('exam_questions.question_id, exam_questions.score, exam_questions.order,
          questions.id, questions.enunciation, questions.type_question, exam_questions.annulled')
        .order('exam_responses.id')
    end
  end

  def self.question_current(exam_id, id)
    exam_questions = ExamQuestion.joins(:question)
      .where(exam_questions: {exam_id: exam_id, annulled: false, use_question: true},
        questions: {status: true, id: id})
      .select('exam_questions.question_id, exam_questions.score, exam_questions.order,
        questions.id, questions.enunciation, questions.type_question, exam_questions.annulled')

    exam_questions
  end  

  def self.list_correction(exam_id, raffle_order = false)
    ExamQuestion.joins(:question)
      .where(exam_questions: {exam_id: exam_id, use_question: true},
        questions: {status: true})
      .select('exam_questions.question_id, exam_questions.score, exam_questions.order,
        questions.id, questions.enunciation, questions.type_question, exam_questions.annulled')
      .order((raffle_order ? "RANDOM()" : "exam_questions.order"))
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

  def can_save?
    raise 'cant_change_after_published' if exam.status && (new_record? || question.status)
  end

  def unpublish
    exam.update_attributes status: false
  end

end
