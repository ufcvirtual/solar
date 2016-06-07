class Exam < Event
  include AcademicTool

  GREATER, AVERAGE, LAST = 0, 1, 2
  OFFER_PERMISSION, GROUP_PERMISSION = true, true

  belongs_to :schedule

  has_many :allocations, through: :allocation_tags

  has_many :exam_questions, dependent: :destroy
  has_many :questions     , through: :exam_questions
  has_many :exam_users    , through: :academic_allocations
  has_many :exam_user_attempts, through: :exam_users
  has_many :exam_responses, through: :exam_user_attempts

  validates :name, :duration, :number_questions, :attempts, presence: true
  validates :name, length: { maximum: 99 }
  validates :number_questions, :attempts, :duration, numericality: { greater_than_or_equal_to: 1, allow_blank: false }
  validates :start_hour, presence: true, if: lambda { |c| c[:start_hour].blank?  && !c[:end_hour].blank? }
  validates :end_hour  , presence: true, if: lambda { |c| !c[:start_hour].blank? && c[:end_hour].blank?  }

  validate :can_edit?, only: :update
  validate :check_hour, if: lambda { |c| !c[:start_hour].blank? && !c[:end_hour].blank?  }

  before_validation proc { self.schedule.check_end_date = true }, if: 'schedule' # mandatory final date

  accepts_nested_attributes_for :schedule

  before_destroy :can_destroy?

  before_save :set_status, :set_can_publish, on: :update

  after_save :set_random_questions, if: 'status_changed? || random_questions_changed? || number_questions_changed?'
  after_save :recalculate_grades,   if: 'attempts_correction_changed?'
  after_save :send_result_emails,   if: 'result_email_changed? && result_email'

  def recalculate_grades(user_id=nil, allocation_tag_id=nil)
    # chamar metodo de correção dos itens respondidos para todos os que existem
    list_exam_user = self.list_exam_correction(user_id, allocation_tag_id)
    list_exam_user.each do |exam_user|
      self.correction_exams(exam_user.id)
      grade = self.get_grade(exam_user.id)
      ExamUser.update(exam_user.id, grade: grade.round(2)) 
    end
  end

  def send_result_emails
    # enviar email com notas se já tiver encerrado período
  end


  def list_exam_correction(user_id=nil, allocation_tag_id=nil)
    query_user = ""
    query_alloc = ""
    query_user = "exam_users.user_id =#{user_id} AND " unless user_id.blank? 
    query_alloc = "allocation_tag_id =#{allocation_tag_id} AND " unless allocation_tag_id.blank?   
    list_exam_user = ExamUser.joins("LEFT JOIN academic_allocations ON exam_users.academic_allocation_id = academic_allocations.id")
                    .joins("LEFT JOIN exams ON exams.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Exam' AND exams.status=TRUE")
                    .joins("LEFT JOIN exam_user_attempts ON exam_user_attempts.exam_user_id = exam_users.id")
                    .joins("LEFT JOIN schedules ON exams.schedule_id = schedules.id")
                    .where(query_user + query_alloc + "exams.id = ? ", self.id)
                    .select("DISTINCT exam_users.id AS id") 
  end  
  
  def correction_exams(exam_user_id)
    
    list_attempt = ExamUserAttempt.where(exam_user_id: exam_user_id)
    list_attempt.each do |exam_user_attempt|                
        grade_exam = 0
        questions_exam = ExamQuestion.list_correction(self.id, self.raffle_order)
        questions_exam.each do |question|
          qtd_iten_true_user = 0
          if question.annulled
            grade_question =  question.score
          else  
            qtd_iten_true_user = self.count_itens_correction_question_att(exam_user_attempt, question)
            if question.type_question.to_i == Question::UNIQUE  
                grade_question = qtd_iten_true_user * question.score
            else
              qtd_itens_question = self.count_itens_question(question)
              qtd_itens_true = self.count_itens_correction_question(question)
              qtd_itens_false = qtd_itens_question - qtd_itens_true

              qtd_iten_false_user = self.count_itens_correction_question_att(exam_user_attempt, question, false)
              qtd_item_false_user_t = qtd_itens_false - qtd_iten_false_user

              score_item = question.score / qtd_itens_question
              grade_question = score_item * (qtd_item_false_user_t+qtd_iten_true_user)
            end  
          end  
          grade_exam = grade_exam + grade_question
         # puts ("ExamAtt: #{exam_user_attempt.id} questao: #{question.question_id} scores: #{question.score}  nota:#{grade_question} qtd Item : #{qtd_itens_question} Qtd Correto: #{qtd_itens_true} Usuario: #{qtd_iten_true_user} Falso: #{qtd_itens_false} Usuario: #{qtd_item_false_user_t}")
        end
        grade_exam = grade_exam > 10 ? 10.00 : grade_exam 
        ExamUserAttempt.update(exam_user_attempt.id, grade: grade_exam.round(2), end: Date.today, complete: true)  
    end  
  end 

  def count_itens_correction_question(question)
    qtd = QuestionItem.where('question_id = ? AND value = ?', question.id, true).count
  end
  def count_itens_question(question)
    qtd = QuestionItem.where('question_id = ? ', question.id).count
  end 

  def count_itens_correction_question_att(exam_user_attempt, question, t=true)
    qtd_att_correction = ExamUserAttempt.joins("LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id")
                         .joins("LEFT JOIN exam_responses_question_items ON exam_responses_question_items.exam_response_id = exam_responses.id")
                         .joins("LEFT JOIN question_items ON  question_items.id = exam_responses_question_items.question_item_id")
                         .where('question_items.value = ? AND question_items.question_id = ? AND exam_user_attempts.id = ?', t, question.id, exam_user_attempt.id).count
  end  

  def copy_dependencies_from(exam_to_copy)
    unless exam_to_copy.exam_questions.empty?
      exam_to_copy.exam_questions.each do |eq|
        ExamQuestion.create! eq.attributes.except('id').merge({ exam_id: id })
      end
    end
  end

  def ended?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    endt      = (has_hours ? (schedule.end_date.beginning_of_day + end_hour.split(':')[0].to_i.hours + end_hour.split(':')[1].to_i.minutes) : schedule.end_date.end_of_day)
    Time.now > endt
  end

  def started?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    startt    = (has_hours ? (schedule.start_date.beginning_of_day + start_hour.split(':')[0].to_i.hours + start_hour.split(':')[1].to_i.minutes) : schedule.start_date.beginning_of_day)
    Time.now >= startt
  end

  def on_going?
    has_hours = (!start_hour.blank? && !end_hour.blank?)
    startt    = (has_hours ? (schedule.start_date.beginning_of_day + start_hour.split(':')[0].to_i.hours + start_hour.split(':')[1].to_i.minutes) : schedule.start_date.beginning_of_day)
    endt      = (has_hours ? (schedule.end_date.beginning_of_day + end_hour.split(':')[0].to_i.hours + end_hour.split(':')[1].to_i.minutes) : schedule.end_date.end_of_day)
    Time.now.between?(startt,endt)
  end

  def on_going_changed?
    has_hours = (!start_hour_was.blank? && !start_hour_was.blank?)
    startt    = (has_hours ? (schedule.start_date_was.beginning_of_day + start_hour_was.split(':')[0].to_i.hours + start_hour_was.split(':')[1].to_i.minutes) : schedule.start_date_was.beginning_of_day)
    endt      = (has_hours ? (schedule.end_date_was.beginning_of_day + end_hour_was.split(':')[0].to_i.hours + end_hour_was.split(':')[1].to_i.minutes) : schedule.end_date_was.end_of_day)
    Time.now.between?(startt,endt)
  end

  def check_hour
    errors.add(:start_hour, I18n.t('exams.error.same_day')) if schedule.start_date != schedule.end_date
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if !end_hour.blank? && !start_hour.blank? && (end_hour.rjust(5, '0') < start_hour.rjust(5, '0'))
  end

  def def_hour
    if (schedule.start_date_changed? || schedule.end_date_changed?) && schedule.start_date_changed? != schedule.end_date_changed?
      self.start_hour = nil
      self.end_hour = nil
    end
  end

  def can_edit?
    return true if !status # if draft
    return true if schedule.start_date_was > Date.today # if has not started yet
    if on_going_changed?
      unless start_hour.blank? || start_hour_was.blank?
        sh  = start_hour.split(':')
        shw = start_hour_was.split(':')
        errors.add(:start_hour, I18n.t('exams.error.hour_later')) if (sh[0].to_i > shw[0].to_i || (!start_hour_changed? && sh[1].to_i > shw[1].to_i) )
      end
      unless end_hour.blank? || end_hour_was.blank?
        eh  = end_hour.split(':')
        ehw = end_hour_was.split(':')
        errors.add(:end_hour, I18n.t('exams.error.hour_earlier')) if (eh[0].to_i < ehw[0].to_i || (!start_hour_changed? && eh[1].to_i < ehw[1].to_i) )
      end
      errors.add(:duration, I18n.t('exams.error.cant_be_smaller'))            if duration < duration_was
      errors.add(:random_questions, I18n.t('exams.error.cant_change'))        if random_questions_changed?
      errors.add(:raffle_order, I18n.t('exams.error.cant_change'))            if raffle_order_changed?
      errors.add(:number_questions, I18n.t('exams.error.cant_change'))        if number_questions_changed?
      errors.add(:attempts, I18n.t('exams.error.cant_be_smaller'))            if attempts < attempts_was
      schedule.errors.add(:start_date, I18n.t('exams.error.cant_be_smaller')) if schedule.start_date < schedule.start_date_was
      errors.add(:block_content, I18n.t('exams.error.cant_change'))           if block_content_changed?
    elsif ended?
      schedule.errors.add(:end_date, I18n.t('exams.error.cant_be_smaller')) if schedule.end_date_changed? && schedule.end_date < schedule.end_date_was
      schedule.errors.add(:start_date, I18n.t('exams.error.cant_change'))   if schedule.start_date_changed? && (exam_users.any? || (schedule.start_date > schedule.start_date_was))
      errors.add(:duration, I18n.t('exams.error.cant_change'))         if duration_changed?
      errors.add(:random_questions, I18n.t('exams.error.cant_change')) if random_questions_changed?
      errors.add(:raffle_order, I18n.t('exams.error.cant_change'))     if raffle_order_changed?
      errors.add(:number_questions, I18n.t('exams.error.cant_change')) if number_questions_changed?
      errors.add(:attempts, I18n.t('exams.error.cant_be_smaller'))     if attempts < attempts_was
      errors.add(:block_content, I18n.t('exams.error.cant_change'))    if block_content_changed?
      errors.add(:attempts_correction, I18n.t('exams.error.cant_change')) if attempts_correction_changed?
    end
  end

  def set_status
    self.status = false if number_questions_changed? && questions.where(status: true).count < number_questions
    return true
  end

  def set_can_publish
    self.can_publish = true
    return true
  end

  def self.exams_by_ats(ats)
    Exam.joins(:academic_allocations, :schedule)
        .joins('LEFT JOIN exam_questions ON exam_questions.exam_id = exams.id')
        .joins("LEFT JOIN questions ON exam_questions.question_id = questions.id AND questions.status = 't'")
        .where(academic_allocations: { allocation_tag_id: ats })
        .select('exams.*, COUNT(questions.id) AS questions_count')
        .group('exams.id')
        .uniq('exams.id')
  end
  
  def self.my_exams(allocation_tag_ids)
  	exams = Exam.joins(:academic_allocations, :schedule)
      .where(academic_allocations: {allocation_tag_id: allocation_tag_ids},
          status: true)
      .select('DISTINCT exams.*, schedules.start_date as start_date, schedules.end_date as end_date') 
      .order('schedules.start_date')
  end

  def get_questions(user_id = nil)
    query = []
    query << "exam_questions.exam_id = #{id}"
    query << "(questions.user_id = #{user_id} OR questions.updated_by_user_id = #{user_id} OR questions.privacy = 'f')" unless user_id.nil?

    Question.find_by_sql <<-SQL
      SELECT questions.id, exam_questions.order, exam_questions.annulled, exam_questions.updated_at, questions.enunciation, questions.type_question, questions.status, questions.privacy, exam_questions.id AS exam_question_id,
        authors.name AS author_name,
        replace(replace(translate(array_agg(distinct labels.name)::text,'{}', ''),'\"', ''),',',', ') AS labels
      FROM questions
      JOIN exam_questions ON questions.id = exam_questions.question_id
      LEFT JOIN users AS authors ON questions.user_id = authors.id
      LEFT JOIN question_labels_questions AS qlq    ON qlq.question_id = questions.id
      LEFT JOIN question_labels           AS labels ON labels.id = qlq.question_label_id
      WHERE #{query.join(' AND ')}
      GROUP BY questions.id, exam_questions.order, exam_questions.annulled, exam_questions.updated_at, questions.enunciation, questions.type_question, questions.status, questions.privacy, authors.name, exam_questions.id
      ORDER BY exam_questions.order ASC
    SQL
  end

  def can_destroy?
    raise 'started'     if status && on_going?
    raise 'has_answers' if exam_users.any?
  end

  def can_change_status?
    raise 'minimum_questions' if !status && questions.where(status: true).count < number_questions
    raise 'started'           if status && on_going?
    raise 'has_answers'       if status && exam_users.any?
    raise 'imported'          if !status && !can_publish
    raise 'change_period'     if !status && started?
    # raise 'autocorrect' if !status && questions.where(type: [0,1,2])
  end

  def can_import?(question = nil)
    raise 'cant_change_after_published' if status
    raise 'already_exists' if !question.nil? && questions.where(id: question.id).any?
  end

  def next_lesson_order
    exam_questions.maximum(:order).next rescue 1
  end

  def allocation_tag_info
    [(groups.first.try(:offer) || offers.first).allocation_tag.info, groups.map(&:code).join(', ')].join(' - ')
  end

  def self.by_name_and_allocation_tags_ids(name, allocation_tags_ids)
    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }, name: name).uniq
  end

  def next_question_order
    exam_questions.maximum(:order).next rescue 1
  end

  def correction_type
    case attempts_correction
    when Exam::GREATER; I18n.t('exams.form.config.greater')
    when Exam::AVERAGE; I18n.t('exams.form.config.average')
    when Exam::LAST; I18n.t('exams.form.config.laast')
    end
  end

  def info(user_id, allocation_tags_ids)
    academic_allocation = academic_allocations.where(allocation_tag_id: allocation_tags_ids).first
    return unless academic_allocation

    info = academic_allocation.exam_users.where({user_id: user_id}).first.try(:info) || {complete: false}
    info = {situation: situation(info[:complete], info[:grade], info[:responses], info[:attempts])}.merge(info)
    {count: percent(number_questions, info[:responses])}.merge(info)
  end

  def situation(complete, grade = nil, exam_responses = 0, user_attempts = 0)
    case
    when !started?                                                      then 'not_started'
    when on_going? && exam_responses == 0                               then 'to_answer'
    when on_going? && !complete                                         then 'not_finished'
    when on_going? && (attempts > user_attempts)                        then 'retake'
    when !grade.blank? && ended?                                        then 'corrected'
    when complete && (attempts == user_attempts)                        then 'finished'
    when ended? && user_attempts != 0 && grade.blank?                   then 'not_corrected'
    else
      'not_answered'
    end
  end

  def self.find_or_create_exam_user(exam, current_user_id, allocation_tags_ids)
    academic_allocation = AcademicAllocation.where(academic_tool_id: exam.id, academic_tool_type: 'Exam',
        allocation_tag_id: allocation_tags_ids).first
    exam_user = exam.exam_users.where(user_id: current_user_id, academic_allocation_id: academic_allocation.id).first_or_create
    exam_user
  end

  def self.find_or_create_exam_user_attempt(exam_user_id)
    @exam_users = ExamUser.where(id: exam_user_id).first
    @exam_user_attempts = @exam_users.exam_user_attempts
    @exam_user_attempt_last = @exam_user_attempts.last

    if (@exam_user_attempt_last.nil? || (@exam_user_attempt_last.complete? && @exam_user_attempt_last.exam.attempts > @exam_user_attempts.count))
      @exam_users.exam_user_attempts.build(exam_user_id: exam_user_id, start: Time.now).save
      @exam_user_attempt_last = ExamUserAttempt.where(exam_user_id: exam_user_id)
    end

    @exam_user_attempt_last
  end

  def responses_question_user(user_id, question_id, question_item_id, exam_user_id, id)
    @response_question_user = nil
    mod_correct_exam = self.attempts_correction
    grade = ExamUserAttempt.where(exam_user_id: exam_user_id).maximum(:grade)

    if grade 
      if mod_correct_exam == Exam::GREATER
        euat = id =  ExamUserAttempt.where(exam_user_id: exam_user_id, grade: grade).last
      elsif mod_correct_exam == Exam::AVERAGE
        @response_question_user =  ExamUserAttempt.joins('LEFT JOIN exam_users ON exam_user_attempts.exam_user_id = exam_users.id')
            .joins('LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id')
            .joins('LEFT JOIN exam_responses_question_items ON exam_responses_question_items.exam_response_id = exam_responses.id')        
            .where('user_id = ? AND question_id = ? AND question_item_id = ? AND exam_user_attempts.id = ? AND question_item_id IS NOT NULL', user_id, question_id, question_item_id, id)
            .select("question_item_id").last             
      else
        euat = ExamUserAttempt.where(exam_user_id: exam_user_id).last
      end 
      if mod_correct_exam != Exam::AVERAGE
          @response_question_user =  ExamUserAttempt.joins('LEFT JOIN exam_users ON exam_user_attempts.exam_user_id = exam_users.id')
            .joins('LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id')
            .joins('LEFT JOIN exam_responses_question_items ON exam_responses_question_items.exam_response_id = exam_responses.id')        
            .where('exam_user_attempts.id = ? AND user_id = ? AND question_id = ? AND question_item_id = ?', euat.id, user_id, question_id, question_item_id)
            .select("question_item_id").last   
      end 
    end  
    @response_question_user
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

  def set_random_questions
    exam_questions.update_all use_question: false
    if status
      query_order = (random_questions ? 'RANDOM()' : 'exam_questions.order')
      ExamQuestion.joins(:question).where(exam_questions: { exam_id: id }, questions: { status: true }).limit(number_questions).order(query_order).update_all use_question: true
    end
  end

  def can_add_group?(ats = [])
    !(started? && status)
  end

  def can_unbind?(groups)
    can_remove_groups?(groups)    
  end

  def can_remove_groups?(groups)
    return false if status && on_going?
    return false if exam_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'Exam', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).any?
  end

  def get_grade(exam_user_id)
    attempts = ExamUserAttempt.where(exam_user_id: exam_user_id)

    case attempts_correction
    when Exam::GREATER; attempts.maximum(:grade)
    when Exam::AVERAGE; attempts.average(:grade)
    else 
      attempts.last.grade
    end
  end
  
  def self.get_id_exam_user_attempt(mod_correct_exam, exam_user_id)
    if mod_correct_exam == Exam::GREATER
      max_grade = ExamUserAttempt.where(exam_user_id: exam_user_id).maximum(:grade)
      id =  ExamUserAttempt.where(exam_user_id: exam_user_id, grade: max_grade).last.id
    elsif mod_correct_exam == Exam::LAST
      id = ExamUserAttempt.where(exam_user_id: exam_user_id).last.id
    end 
    id
  end

  private

    def percent(total, answered)
      ((answered.to_f/total.to_f)*100).round(2)
    end

end
