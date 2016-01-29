class Exam < Event
  include AcademicTool

  GREATER, AVARAGE, LAST = 0, 1, 2
  OFFER_PERMISSION, GROUP_PERMISSION = true, true

  belongs_to :schedule

  has_many :allocations, through: :allocation_tags

  has_many :exam_questions, dependent: :destroy
  has_many :questions     , through: :exam_questions
  has_many :exam_users    , through: :academic_allocations
  has_many :exam_responses, through: :exam_users

  validates :name, :duration, :number_questions, :attempts, presence: true
  validates :name, length: { maximum: 99 }
  validates :number_questions, :attempts, numericality: { greater_than_or_equal_to: 1, allow_blank: false }
  validates :start_hour, presence: true, if: lambda { |c| c[:start_hour].blank?  && !c[:end_hour].blank? }
  validates :end_hour  , presence: true, if: lambda { |c| !c[:start_hour].blank? && c[:end_hour].blank?  }

  validate :can_edit?, only: :update
  validate :check_hour, if: lambda { |c| !c[:start_hour].blank? && !c[:end_hour].blank?  }

  before_validation proc { self.schedule.check_end_date = true }, if: 'schedule' # mandatory final date

  accepts_nested_attributes_for :schedule

  before_destroy :can_destroy?

  before_save :set_status, :set_can_publish, on: :update

  after_save :set_random_questions, if: '(status_changed? && status) || (!status && random_questions_changed? && !random_questions)'
  after_save :recalculate_grades,   if: 'attempts_correction_changed?'
  after_save :send_result_emails,   if: 'result_email_changed? && result_email'

  def recalculate_grades
    # chamar metodo de correção dos itens respondidos para todos os que existem
  end

  def send_result_emails
    # enviar email com notas se já tiver encerrado período
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
    when Exam::AVARAGE; I18n.t('exams.form.config.avarage')
    when Exam::LAST; I18n.t('exams.form.config.laast')
    end
  end

  def info(user_id, allocation_tags_ids)
    academic_allocation = academic_allocations.where(allocation_tag_id: allocation_tags_ids).first
    return unless academic_allocation

    info = academic_allocation.exam_users.where({user_id: user_id}).first.try(:info) || {complete: false}
    info = {situation: situation(info[:complete], info[:grade], exam_responses.count)}.merge(info)
    {count: percent(number_questions, exam_responses.count)}.merge(info)
  end

  def situation(complete, grade = nil, exam_responses = 0)
    case
    when schedule.start_date.to_date > Date.current                    then 'not_started'
    when (schedule.end_date.to_date >= Date.today)                     then 'to_answer'
    when exam_responses > 0 && !complete                               then 'not_finished'
    when complete                                                      then 'finished'
    when !grade.nil?                                                   then 'corrected'
    when (schedule.end_date.to_date < Date.today)                      then 'not_answered'
    else
      '-'
    end
  end

  def self.create_exam_user(exam, current_user_id, allocation_tags_ids)
    @exam_users = exam.exam_users.where(:user_id => current_user_id).first
    if @exam_users.nil?
      @academic_allocation = AcademicAllocation.where(academic_tool_id: exam.id, academic_tool_type: 'Exam',
        allocation_tag_id: allocation_tags_ids).first
      exam.exam_users.build(:user_id => current_user_id, :academic_allocation_id => @academic_allocation.id).save 
      @exam_users = exam.exam_users.where(:user_id => current_user_id).first
    end
    return @exam_users
  end

  def self.set_start_time(exam_users_id)
    @exam_user = ExamUser.find(exam_users_id)
    if @exam_user.start.nil?
      @exam_user.start = Time.now 
      @exam_user.save
    end
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
    ExamQuestion.joins(:question).where(exam_questions: {exam_id: id}, questions: { status: true }).limit(number_questions).order('RANDOM()').update_all use_question: true if random_questions
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

  private

    def percent(total, answered)
      ((answered.to_f/total.to_f)*100).round(2)
    end

end
