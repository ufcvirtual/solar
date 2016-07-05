class ExamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Exam' }

  has_one :exam,     through: :academic_allocation
  has_one :allocation_tag, through: :academic_allocation

  has_many :exam_user_attempts, dependent: :destroy
  has_many :exam_responses, through: :exam_user_attempts
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items

  attr_accessor :merge

  def answered_questions(last_attempt=nil)
    last_attempt = exam_user_attempts.last if last_attempt.blank?
    return 0 if last_attempt.blank?
    Question.joins(question_items: [exam_responses: :exam_user_attempt]).where(exam_user_attempts: {id: last_attempt.id}).pluck(:id).uniq.count rescue 0
  end

  def info
    complete_attempts = exam.ended? ? exam_user_attempts : exam_user_attempts.where(complete: true)
    last_attempt = exam_user_attempts.last

    { grade: self.grade, complete: last_attempt.try(:complete), attempts: exam_user_attempts.count, responses: answered_questions(last_attempt) }
  end

  def has_attempt(exam)
    (exam_user_attempts.empty? || !exam_user_attempts.last.complete || (exam.attempts > exam_user_attempts.count))
  end

  def delete_with_dependents
    exam_user_attempts.map(&:delete_with_dependents)
    self.delete
  end

  def count_attempts
    count = exam_user_attempts.where(complete: true).count
    count = 1 if count.zero?
    count
  end

  def find_or_create_exam_user_attempt
    exam_user_attempt_last = exam_user_attempts.last

    (exam_user_attempt_last.nil? || (exam_user_attempt_last.complete && exam_user_attempt_last.exam.attempts > exam_user_attempts.count)) ?  exam_user_attempts.create(exam_user_id: id, start: Time.now) : exam_user_attempt_last
  end

  def finish_attempt
    last_attempt = exam_user_attempts.last
    last_attempt.end = DateTime.now
    last_attempt.complete = true
    last_attempt.save
  end

  def status
    last_attempt  = exam_user_attempts.last
    user_attempts = exam_user_attempts.count
    case
    when !exam.started?                                                      then 'not_started'
    when exam.on_going? && (exam_responses.blank? || exam_responses == 0)    then 'to_answer'
    when exam.on_going? && !last_attempt.complete                            then 'not_finished'
    when exam.on_going? && (exam.attempts > user_attempts)                   then 'retake'
    when !grade.blank? && exam.ended?                                        then 'corrected'
    when last_attempt.complete && (exam.attempts == user_attempts)           then 'finished'
    when exam.ended? && (user_attempts != 0 && !user_attempts.blank?) && grade.blank? then 'not_corrected'
    else
      'not_answered'
    end
  end

end
