class Exam < Event
  include AcademicTool
  include EvaluativeTool
  include Controlled

  GREATER, AVERAGE, LAST = 0, 1, 2
  OFFER_PERMISSION, GROUP_PERMISSION = true, true

  belongs_to :schedule

  has_many :allocations, through: :allocation_tags

  has_many :exam_questions, dependent: :destroy
  has_many :questions     , through: :exam_questions
  has_many :exam_user_attempts, through: :academic_allocation_users
  has_many :exam_responses, through: :exam_user_attempts
  # has_many :ip_fakes, through: :ip_reals

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
  after_save :recalculate_grades,   if: 'attempts_correction_changed? || (result_email_changed? && result_email)'

  def recalculate_grades(user_id=nil, ats=nil, all=nil)
    if ended?
      grade = 0.00
      wh = 0
      # chamar metodo de correção dos itens respondidos para todos os que existem
      list_exam_correction(user_id, ats, all).each do |acu|
        correction_exams(acu.id)
        grade = get_grade(acu.id)
        grade = grade ? grade : 0.00
        working_hours = (acu.academic_allocation.frequency ? ({working_hours: (wh = acu.academic_allocation.max_working_hours)}) : {})
        acu.update_attributes({grade: (grade > 10 ? 10 : grade.round(2)), status: AcademicAllocationUser::STATUS[:evaluated]}.merge!(working_hours))
        acu.recalculate_final_grade(acu.allocation_tag_id)
        send_result_emails(acu, grade) if result_email
      end
      [grade.round(2), wh]
    else
      errors.add(:base, I18n.t('exams.errors.not_finished'))
    end
  end

  def send_result_emails(acu, grade)
    # enviar email com notas se já tiver encerrado período
    user = User.find(acu.user_id)
    subject = I18n.t('exams.result_exam_user.subject')
    recipients = "#{user.name} <#{user.email}>"
    files = Array.new
    msg = self.grade_msg_template(user, grade, acu.allocation_tag)
    Thread.new do
      Notifier.send_mail(recipients, subject, msg, files, nil).deliver
    end
  end

  def grade_msg_template(user, grade, at)
   label_cur  = at.curriculum_unit_types
   label_info = at.info
    %{
      <b> #{I18n.t('exams.result_exam_user.salutation')} #{user.name},</b><br/>
      #{I18n.t('exams.result_exam_user.exam_name')} #{self.name} #{I18n.t('exams.result_exam_user.email_of')} #{label_cur} - #{label_info} #{I18n.t('exams.result_exam_user.email_infor_compl')}<br/>
      __________________________________________________________________________________________________________________________<br/><br/>
      #{I18n.t('exams.result_exam_user.exam_grade')} #{grade.round(2)} <br/>

      #{I18n.t('exams.result_exam_user.email_infor')}<br/><br/>

      #{I18n.t('exams.result_exam_user.email')}
    }
  end

  def list_exam_correction(user_id=nil, ats=nil, all=nil)
    query = []
    query << "academic_allocation_users.user_id = :user_id "   unless user_id.blank?
    query << "academic_allocations.allocation_tag_id IN (#{ats}) "  unless ats.blank?
    query << "exam_user_attempts.grade IS NULL" unless all.blank?
    query << "(schedules.end_date < current_date OR (schedules.end_date = current_date AND end_hour IS NOT NULL AND end_hour != '' AND end_hour::time < current_time))"

    AcademicAllocationUser.joins(academic_allocation: [exam: :schedule])
            .joins("LEFT JOIN exam_user_attempts ON exam_user_attempts.academic_allocation_user_id = academic_allocation_users.id")
            .where(exams: { id: id, status: true }).where(query.join(' AND '), { user_id: user_id })
            .select("DISTINCT academic_allocation_users.*, academic_allocations.allocation_tag_id")
  end

  def correction_exams(acu_id)
    questions_exam = ExamQuestion.list_correction(id, raffle_order)
    attempts = ExamUserAttempt.where(academic_allocation_user_id: acu_id)
    list_attempt = attempts.where(complete: true)
    (list_attempt.any? ? list_attempt : [attempts.first]).compact.each do |exam_user_attempt|
      grade_exam = 0

      questions_exam.each do |question|
        if question.annulled
          grade_question =  question.score
        else
          if question.type_question.to_i == Question::UNIQUE
            grade_question = count_correct_items(exam_user_attempt, question, true) * question.score
          elsif question.type_question.to_i == Question::MULTIPLE
            score_item = question.score / question.question_items.where(value: true).count
            count_correct_items = count_correct_items(exam_user_attempt, question, true)
            count_wrong_items   = count_wrong_items(exam_user_attempt, question)
            final_items = count_correct_items - count_wrong_items
            grade_question = (final_items < 0 ? 0 : final_items) * score_item
          else # V/F
            score_item = question.score / question.question_items.count
            count_correct_items = count_correct_items(exam_user_attempt, question)
            grade_question = count_correct_items * score_item
          end
        end
        grade_exam = grade_exam + grade_question
      end
      grade_exam = grade_exam > 10 ? 10.00 : grade_exam

      if exam_user_attempt.end
        ExamUserAttempt.update(exam_user_attempt.id, grade: grade_exam.round(2), complete: true)
      else
        ExamUserAttempt.update(exam_user_attempt.id, grade: grade_exam.round(2), end: DateTime.now, complete: true)
      end
    end
  end

  def count_correct_items(exam_user_attempt, question, t=nil)
    query = t.blank? ? '' : " AND question_items.value = #{t}"
    ExamUserAttempt.joins("LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id")
                   .joins("LEFT JOIN exam_responses_question_items ON exam_responses_question_items.exam_response_id = exam_responses.id")
                   .joins("LEFT JOIN question_items ON  question_items.id = exam_responses_question_items.question_item_id")
                   .where('question_items.question_id = ? AND exam_user_attempts.id = ? AND exam_responses_question_items.value = question_items.value' + query, question.id, exam_user_attempt.id).count
  end

  def count_wrong_items(exam_user_attempt, question)
    ExamUserAttempt.joins("LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id")
                   .joins("LEFT JOIN exam_responses_question_items ON exam_responses_question_items.exam_response_id = exam_responses.id")
                   .joins("LEFT JOIN question_items ON  question_items.id = exam_responses_question_items.question_item_id")
                   .where('question_items.question_id = ? AND exam_user_attempts.id = ? AND (exam_responses_question_items.value != question_items.value OR exam_responses_question_items.question_item_id IS NULL)', question.id, exam_user_attempt.id).count
  end

  def can_correct?(user_id, ats)
    AcademicAllocationUser.joins(academic_allocation: [exam: :schedule]).joins('LEFT JOIN exam_user_attempts ON exam_user_attempts.academic_allocation_user_id = academic_allocation_users.id').where("schedules.end_date < current_date OR (schedules.end_date = current_date AND end_hour::time < current_time)").where(user_id: user_id, exams: { status: true, id: id }, academic_allocations: { allocation_tag_id: ats }).where('exam_user_attempts.grade IS NULL').any?
  end

  def self.correction_cron
    list_exam = Exam.includes(:schedule).where("schedules.end_date<current_date AND auto_correction=TRUE")
    list_exam.each do |exam|
      exam.recalculate_grades(nil, nil, true)
    end
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
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if (end_hour.rjust(5, '0') < start_hour.rjust(5, '0'))
    errors.add(:duration, I18n.t('exams.error.duration_and_hour')) if !duration.nil? && (Time.parse(end_hour) - Time.parse(start_hour))/60 < duration
  end

  def def_hour
    if (schedule.start_date_changed? || schedule.end_date_changed?) && schedule.start_date_changed? != schedule.end_date_changed?
      self.start_hour = nil
      self.end_hour = nil
    end
  end

  def can_edit?
    return true if !status # if draft
    return true unless started? # if has not started yet
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
      schedule.errors.add(:start_date, I18n.t('exams.error.cant_change'))   if schedule.start_date_changed? && (academic_allocation_users.any? || (schedule.start_date > schedule.start_date_was))
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
        .select('exams.*')
        .group('exams.id')
        .uniq('exams.id')
  end

  def self.my_exams(allocation_tag_ids)
  	Exam.joins(:academic_allocations, :schedule)
      .where(academic_allocations: {allocation_tag_id: allocation_tag_ids},
          status: true)
      .select('DISTINCT exams.*, schedules.start_date as start_date, schedules.end_date as end_date, evaluative, frequency')
      .order('id DESC')
  end

  def get_questions(user_id = nil)
    query = []
    query << "exam_questions.exam_id = #{id}"
    query << "(questions.user_id = #{user_id} OR questions.updated_by_user_id = #{user_id} OR questions.privacy = 'f')" unless user_id.nil?

    Question.find_by_sql <<-SQL
      SELECT questions.id, exam_questions.order, exam_questions.annulled, exam_questions.updated_at, questions.enunciation, questions.type_question, questions.status, questions.privacy, exam_questions.id AS exam_question_id,
        authors.name AS author_name,
        updated_by.name AS updated_by_name,
        replace(replace(translate(array_agg(distinct labels.name)::text,'{}', ''),'\"', ''),',',', ') AS labels
      FROM questions
      JOIN exam_questions ON questions.id = exam_questions.question_id
      LEFT JOIN users AS authors ON questions.user_id = authors.id
      LEFT JOIN users AS updated_by ON questions.updated_by_user_id = updated_by.id
      LEFT JOIN question_labels_questions AS qlq    ON qlq.question_id = questions.id
      LEFT JOIN question_labels           AS labels ON labels.id = qlq.question_label_id
      WHERE #{query.join(' AND ')}
      GROUP BY questions.id, exam_questions.order, exam_questions.annulled, exam_questions.updated_at, questions.enunciation, questions.type_question, questions.status, questions.privacy, authors.name, exam_questions.id, updated_by.name
      ORDER BY exam_questions.order ASC
    SQL
  end

  def can_destroy?
    raise 'started'     if status && on_going?
    raise 'has_answers' if academic_allocation_users.any?
  end

  def can_change_status?
    raise 'minimum_questions' if !status && exam_questions.joins(:question).where(questions:{ status: true }, annulled: false).count < number_questions
    raise 'started'           if status && on_going?
    raise 'has_answers'       if status && academic_allocation_users.any?
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
    when Exam::LAST; I18n.t('exams.form.config.last')
    end
  end

  def responses_question_user(acu_id, id)
    mod_correct_exam = self.attempts_correction

    if mod_correct_exam == Exam::GREATER
      grade = ExamUserAttempt.where(academic_allocation_user_id: acu_id).maximum(:grade)
      @exam_user_attempt =  ExamUserAttempt.where(academic_allocation_user_id: acu_id, grade: grade).last
    elsif mod_correct_exam == Exam::LAST
      @exam_user_attempt = ExamUserAttempt.where(academic_allocation_user_id: acu_id).last
    else
      @exam_user_attempt = ExamUserAttempt.find(id)
    end
    @exam_user_attempt
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
      ExamQuestion.joins(:question).where(exam_questions: { exam_id: id }, questions: { status: true }, annulled: false).limit(number_questions).order(query_order).update_all use_question: true
    end
  end

  def can_add_group?(ats = [])
    !(started? && status)
  end

  def get_grade(acu_id)
    attempts = ExamUserAttempt.where(academic_allocation_user_id: acu_id)
    case attempts_correction
    when Exam::GREATER; attempts.maximum(:grade)
    when Exam::AVERAGE; attempts.average(:grade)
    else
      attempts.last.grade
    end
  end

  def self.get_exam_user_attempt(mod_correct_exam, acu_id)
    if mod_correct_exam == Exam::GREATER
      max_grade = ExamUserAttempt.where(academic_allocation_user_id: acu_id).maximum(:grade)
      ExamUserAttempt.where(academic_allocation_user_id: acu_id, grade: max_grade).last
    elsif mod_correct_exam == Exam::LAST
      ExamUserAttempt.where(academic_allocation_user_id: acu_id).last
    end
  end

  def self.verify_blocking_content(user_id)
    AcademicAllocationUser.joins("LEFT JOIN academic_allocations ON academic_allocation_users.academic_allocation_id = academic_allocations.id")
                    .joins("LEFT JOIN exams ON exams.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Exam' AND exams.status=TRUE")
                    .joins("LEFT JOIN exam_user_attempts ON exam_user_attempts.academic_allocation_user_id = academic_allocation_users.id")
                    .joins("LEFT JOIN schedules s ON exams.schedule_id = s.id")
                    .where("block_content=true AND complete=false AND user_id=? AND academic_allocation_users.status != 2 AND (uninterrupted = false OR (exam_user_attempts.start + ((interval '1 mins')*duration) >= now())) AND (((current_date > s.start_date) OR (current_date = s.start_date AND (exams.start_hour IS NOT NULL AND exams.end_hour != '' AND current_time>=to_timestamp(exams.start_hour, 'HH24:MI:SS')::time))) AND ((current_date < s.end_date) OR (current_date = s.end_date AND (exams.end_hour IS NOT NULL AND exams.end_hour != '' AND current_time<=to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) )", user_id)
                    .select("DISTINCT block_content").any?
  end

  def self.verify_previous(acu_id)
    ExamUserAttempt.where(academic_allocation_user_id: acu_id).any?
  end

  def self.update_previous(academic_allocation_id, user_id, academic_allocation_user_id)
    # ExamUserAttempt only exists if ACU exists, no need to update previous
    return false
  end

  def self.list_exams(at_id, evaluative=false, frequency=false)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)
    wq = "academic_allocations.evaluative=true AND " if evaluative
    wq = "academic_allocations.frequency=true AND " if frequency
    wq = "academic_allocations.evaluative=false AND academic_allocations.frequency=false AND " if !evaluative && !frequency

    exams  = Exam.joins(:academic_allocations, :schedule)
                 .where(wq + "academic_allocations.allocation_tag_id= ?",  at.id )
                 .select("exams.*, schedules.start_date AS start_date, schedules.end_date AS end_date")
                 .order("start_date")
  end

  def self.percent(total, answered)
    ((answered.to_f/total.to_f)*100).round(2)
  end

end
