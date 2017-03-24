class AcademicAllocation < ActiveRecord::Base

  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag
  has_many :academic_allocation_users

  belongs_to :lesson_module,  foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'LessonModule'"]
  belongs_to :chat_room,      foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'ChatRoom'"]
  belongs_to :exam,           foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'Exam'"]
  belongs_to :assignment,     foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'Assignment'"]
  belongs_to :webconference,  foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'Webconference'"]
  belongs_to :discussion,     foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'Discussion'"]
  belongs_to :schedule_event, foreign_key: 'academic_tool_id', conditions: ["academic_tool_type = 'ScheduleEvent'"]

  has_many :group_assignments, dependent: :destroy

  has_many :discussion_posts, class_name: 'Post', dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :chat_participants, inverse_of: :academic_allocation, dependent: :destroy

  before_save :verify_association_with_allocation_tag

  before_destroy :move_lessons_to_default, if: :lesson_module?

  before_validation :verify_uniqueness

  accepts_nested_attributes_for :chat_participants, allow_destroy: true, reject_if: proc { |attributes| attributes['allocation_id'] == '0' }

  validate :verify_assignment_offer_date_range, if: :assignment?

  validates :weight, presence: true, numericality: { greater_than: 0,  only_integer: true }, if: 'evaluative? && !final_exam?'
  validates :final_weight, presence: true, numericality: { greater_than: 0,  only_integer: true, smaller_than: 101 }, if: 'evaluative? && !final_exam?'
  validates :max_working_hours, presence: true, numericality: { greater_than: 0,  only_integer: true, allow_blank: true }, if: 'frequency? && !final_exam?'

  validate :verify_equivalents, if: 'equivalent_academic_allocation_id_changed? && !equivalent_academic_allocation_id.nil?'
  validate :verify_type, if: "(evaluative || frequency) && academic_tool_type == 'ScheduleEvent'"

  before_save :set_evaluative_params, on: :update, unless: 'new_record?'
  before_save :change_dependencies, on: :update, unless: 'new_record?'

  def set_evaluative_params
    self.frequency = get_curriculum_unit.try(:working_hours).blank? ? false : frequency
    self.max_working_hours = nil unless self.frequency
    if !evaluative
      self.weight = 1
      self.final_weight = 100
      self.final_exam = false
    elsif final_exam
      self.weight = 0
      self.final_weight = 0
      self.equivalent_academic_allocation_id = nil
      self.max_working_hours = 0
      self.frequency = false
    end
    unless equivalent_academic_allocation_id.nil?
      ac = AcademicAllocation.find(equivalent_academic_allocation_id)
      self.weight = ac.weight
      self.final_weight = ac.final_weight
      self.max_working_hours = ac.max_working_hours
    end
  end

  def change_dependencies
    AcademicAllocation.where(equivalent_academic_allocation_id: id).update_all weight: weight, final_weight: final_weight, max_working_hours: max_working_hours
  end

  def verify_type
    if [Recess, Holiday].include? ScheduleEvent.find(academic_tool_id).type_event
      errors.add(:evaluative, I18n.t('evaluative_tools.errors.event_evaluative')) if evaluative
      errors.add(:frequency, I18n.t('evaluative_tools.errors.event_frequency')) if frequency
    end
  end

  def verify_equivalents
    eq_ac = AcademicAllocation.find(equivalent_academic_allocation_id)

    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.single_equivalent')) if AcademicAllocation.where(equivalent_academic_allocation_id: equivalent_academic_allocation_id).where('id != :id', { id: id }).any? && (academic_tool_type != 'ChatRoom' || ChatRoom.where(id: [academic_tool_id, eq_ac.academic_tool_id]).map(&:chat_type).include?(0))

    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.nested')) if AcademicAllocation.where(equivalent_academic_allocation_id: id).any? && !equivalent_academic_allocation_id.nil?
    # errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.same_type')) if academic_tool_type != eq_ac.academic_tool_type

    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.eq_evaluative')) if evaluative != eq_ac.try(:evaluative)
    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.eq_frequency')) if frequency != eq_ac.try(:frequency)

    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.itself')) if id == equivalent_academic_allocation_id

    group = allocation_tag.group
    if eq_ac.allocation_tag_id != allocation_tag_id
      if group.nil?
        errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.equivalent_offer'))
      else
        errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.equivalent_group', group: group.code))
      end
    end
  end

  def assignment?
    academic_tool_type.eql? 'Assignment'
  end

  def lesson_module?
    academic_tool_type.eql? 'LessonModule'
  end

  def webconference?
    academic_tool_type.eql? 'Webconference'
  end

  def copy_group_assignments(to_ac_id, user, ip) # user e IP serão usados no LOG
    ActiveRecord::Base.transaction do
      group_assignments.each do |group|
        group.copy(to_ac_id)
        LogAction.create(log_type: LogAction::TYPE[:create], user_id: user, ip: ip, description: "import_group: #{group.attributes}", academic_allocation_id: to_ac_id)
      end
    end
  end

  def tool_name
    tool = academic_tool_type.constantize.find(academic_tool_id)
    tool.respond_to?(:name) ? tool.name : tool.title
  end

  def tool_type_name
    tool = academic_tool_type.constantize.find(academic_tool_id)



    [I18n.t("activerecord.models.#{academic_tool_type.tableize.singularize}"), tool.respond_to?(:name) ? tool.name : tool.title].join(': ')
  end

  def verify_evaluative
    academic_tool_type.constantize.find(academic_tool_id).verify_evaluatives
  end

  private

    ## antes de salvar, verifica se as allocations_tags passadas permitem a ferramenta em questão.
    def verify_association_with_allocation_tag
      const = case allocation_tag.refer_to
      when 'group'
        :GROUP_PERMISSION
      when 'offer'
        :OFFER_PERMISSION
      when 'curriculum_unit'
        :CURRICULUM_UNIT_PERMISSION
      when 'course'
        :COURSE_PERMISSION
      when 'curriculum_unit_type'
        :CURRICULUM_UNIT_TYPE_PERMISSION
      else
        :NONE
      end

      raise ActiveRecord::AssociationTypeMismatch unless academic_tool.class.const_defined?(const)
      return true
    end

    ## verifica se já existe uma AcademicAllocation com todos os dados iguais
    def verify_uniqueness
      # na criacao ou algum campo modificado na atualizacao
      error = (
        (new_record? || (allocation_tag_id_changed? || academic_tool_type_changed? || academic_tool_id_changed?)) &&
        AcademicAllocation.where(allocation_tag_id: allocation_tag_id, academic_tool_type: academic_tool_type, academic_tool_id: academic_tool_id).any?
      )

      errors.add(:base, I18n.t(:uniqueness, scope: [:activerecord, :errors])) if error
    end

    # Metodos destinados ao Assignment
    ## datas da atividade devem estar no intervalo de datas da oferta
    def verify_assignment_offer_date_range
      if allocation_tag.group && academic_tool.schedule.end_date.to_date > (offer_end_date = allocation_tag.group.offer.end_date)
        message = I18n.t('assignments.notifications.final_date_smaller_than_offer', end_date_offer: I18n.l(offer_end_date)).to_s
        errors.add(:base, message)
        raise "academic_allocation #{message}"
      end
    end

    # Metodos destinados ao Lesson Module
    def move_lessons_to_default
      lesson_module = LessonModule.joins(:academic_allocations).where({is_default: true, academic_allocations: {allocation_tag_id: allocation_tag_id}})
      academic_tool.lessons.update_all(lesson_module_id: lesson_module) unless lesson_module.empty?
    end

    def get_curriculum_unit
      case allocation_tag.refer_to
      when 'group'
        allocation_tag.group.curriculum_unit
      when 'offer'
        allocation_tag.offer.curriculum_unit
      when 'curriculum_unit'
        allocation_tag.curriculum_unit
      else
        nil
      end
    end


end
