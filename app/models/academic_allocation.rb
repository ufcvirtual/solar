class AcademicAllocation < ActiveRecord::Base
  include APILog

  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag
  has_many :academic_allocation_users
  has_many :user_access_lasts

  belongs_to :lesson_module,  -> { where("academic_tool_type = 'LessonModule'")}, foreign_key: 'academic_tool_id'
  belongs_to :chat_room,      -> { where("academic_tool_type = 'ChatRoom'")}, foreign_key: 'academic_tool_id'
  belongs_to :exam,           -> { where("academic_tool_type = 'Exam'")}, foreign_key: 'academic_tool_id'
  belongs_to :assignment,     -> { where("academic_tool_type = 'Assignment'")}, foreign_key: 'academic_tool_id'
  belongs_to :webconference,  -> { where("academic_tool_type = 'Webconference'")}, foreign_key: 'academic_tool_id'
  belongs_to :discussion,     -> { where("academic_tool_type = 'Discussion'")}, foreign_key: 'academic_tool_id'
  belongs_to :schedule_event, -> { where("academic_tool_type = 'ScheduleEvent'")}, foreign_key: 'academic_tool_id'
  belongs_to :notification,   -> { where("academic_tool_type = 'Notification'")}, foreign_key: 'academic_tool_id'

  has_many :group_assignments, dependent: :destroy

  has_many :discussion_posts, class_name: 'Post', dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :log_actions, dependent: :destroy
  has_many :chat_participants, inverse_of: :academic_allocation, dependent: :destroy

  before_save :verify_association_with_allocation_tag, unless: 'allocation_tag_id.blank?'

  before_destroy :move_lessons_to_default, if: 'lesson_module? && force.blank?'

  before_validation :verify_uniqueness

  accepts_nested_attributes_for :chat_participants, allow_destroy: true, reject_if: proc { |attributes| attributes['allocation_id'] == '0' }

  validate :verify_assignment_offer_date_range, if: "assignment? && !(evaluative_changed? || frequency_changed? || final_exam_changed? || equivalent_academic_allocation_id_changed?)"

  validates :weight, presence: true, numericality: { greater_than: 0,  only_float: true }, if: 'evaluative? && !final_exam? && equivalent_academic_allocation_id.nil?'
  validates :final_weight, presence: true, numericality: { greater_than: 0,  only_float: true, smaller_than: 100.1 }, if: 'evaluative? && !final_exam? && equivalent_academic_allocation_id.nil?'
  validates :max_working_hours, presence: true, numericality: { greater_than: 0,  only_float: true, allow_blank: true }, if: 'frequency? && !final_exam? && equivalent_academic_allocation_id.nil?'

  validate :verify_equivalents, if: '(equivalent_academic_allocation_id_changed? && !equivalent_academic_allocation_id.nil?) || (!equivalent_academic_allocation_id.nil? && (frequency_changed? || evaluative_changed?))'
  validate :verify_type, if: "(evaluative || frequency) && academic_tool_type == 'ScheduleEvent'"

  before_save :set_evaluative_params, on: :update, unless: 'new_record?'
  before_save :change_dependencies, on: :update, unless: 'new_record?'
  before_save :set_automatic_frequency, on: :update, if: "frequency"

  after_save :update_acus, on: :update, if: "frequency_automatic && !max_working_hours.blank?"

  before_destroy :set_situation_date
  after_destroy :verify_management

  attr_accessor :merge, :force

  after_create if: 'verify_tool' do
    AcademicTool.send_email(academic_tool, [self], false)
  end

  before_destroy if: 'verify_tool', prepend: true do
    AcademicTool.send_email(academic_tool, [self]) if academic_tool.verify_can_destroy
  end

  def verify_tool
    !allocation_tag_id.nil? && academic_tool.verify_start && merge.nil? && (!academic_tool.respond_to?(:status_changed?) || academic_tool.status) && (allocation_tag.group_id.nil? || allocation_tag.group.status)
  end

  def set_evaluative_params
    uc = get_curriculum_unit
    self.frequency = uc.try(:working_hours).blank? ? false : frequency
    self.max_working_hours = nil unless self.frequency
    if !evaluative
      self.weight = 1
      self.final_weight = 100
      self.final_exam = false
    elsif final_exam
      self.weight = 0
      self.final_weight = 0
      self.max_working_hours = 0
      self.frequency = false
    else
      if uc.try(:curriculum_unit_type_id).to_i == 2
        self.weight = 1
      else
        self.final_weight = 100
      end
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

  def group_to_individual
    academic_allocation_users.each do |acu|
      ga = acu.group_assignment
      unless ga.blank?
        gp = ga.group_participants
        if gp.size == 1
          acu.update_attributes user_id: gp.first.user_id, group_assignment_id: nil
          gp.first.delete
          ga.delete
        else
          gp.each_with_index do |p, idx|
            if idx == (gp.size-1)
              acu.update_attributes group_assignment_id: nil, user_id: p.user_id
            else
              new_acu = AcademicAllocationUser.new(acu.attributes.except('id', 'group_assignment_id', 'user_id').merge!({user_id: p.user_id}))
              new_acu.merge = true
              new_acu.save
              copy_objects(acu.comments, { 'academic_allocation_user_id' => new_acu.id }, true, :files)
              copy_objects(acu.assignment_files, { 'academic_allocation_user_id' => new_acu.id }, true)
              copy_objects(acu.assignment_webconferences, { 'academic_allocation_user_id' => new_acu.id }, true, nil, { to: :set_origin, from: :id })
            end
            p.delete
          end
        end
        ga.delete
      end
    end
  end

  def individual_to_group
    academic_allocation_users.each do |acu|
      ga = GroupAssignment.where(academic_allocation_id: id, group_name: acu.user.name[0..19]).first_or_initialize
      ga.merge = true
      ga.save!
      gp = GroupParticipant.where(user_id: acu.user_id, group_assignment_id: ga.id).first_or_initialize
      gp.merge = true
      gp.save!
      acu.update_attributes group_assignment_id: ga.id
    end
  end

  def verify_equivalents
    eq_ac = AcademicAllocation.find(equivalent_academic_allocation_id)

    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.single_equivalent')) if AcademicAllocation.where(equivalent_academic_allocation_id: equivalent_academic_allocation_id).where('id != :id', { id: id }).any? && (academic_tool_type != 'ChatRoom' || ChatRoom.where(id: [academic_tool_id, eq_ac.academic_tool_id]).map(&:chat_type).include?(0))

    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.nested')) if AcademicAllocation.where(equivalent_academic_allocation_id: id).any? && !equivalent_academic_allocation_id.nil?
    errors.add(:equivalent_academic_allocation_id, I18n.t('evaluative_tools.errors.same_type_af')) if final_exam != eq_ac.final_exam #if academic_tool_type != eq_ac.academic_tool_type

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

  def schedule
    academic_tool.respond_to?(:schedule) ? academic_tool.schedule : academic_tool.initial_time.to_date
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

    def copy_file(file_to_copy_path, file_copied_path)
      unless File.exists? file_copied_path || !(File.exists? file_to_copy_path)
        file = File.new file_copied_path, 'w'
        FileUtils.cp file_to_copy_path, file # copy file content to new file
      end
    end

    def copy_objects(objects_to_copy, merge_attributes={}, is_file = false, nested = nil, call_methods = {})
      objects_to_copy.each do |object_to_copy|
        copy_object(object_to_copy, merge_attributes, is_file, nested, call_methods)
      end
    end

    def copy_object(object_to_copy, merge_attributes={}, is_file = false, nested = nil, call_methods = {})
      new_object = object_to_copy.class.where(object_to_copy.attributes.except('id', 'academic_allocation_user_id').merge!(merge_attributes)).first_or_initialize
      new_object.merge = true if new_object.respond_to?(:merge) # used so call save without callbacks (before_save, before_create)

      new_object.send(call_methods[:to], object_to_copy.send(call_methods[:from])) unless call_methods.empty?
      new_object.save

      copy_file(object_to_copy.attachment.path, new_object.attachment.path) if is_file && object_to_copy.respond_to?(:attachment)
      copy_objects(object_to_copy.send(nested.to_sym), {"#{new_object.class.to_s.tableize.singularize}_id" => new_object.id}, is_file) unless nested.nil?

      new_object
    rescue
      nil
    end

    def set_situation_date
      AllocationTag.where(situation_date_ac_id: id).each do |at|
        last_date = AcademicTool.last_date(at.id, id)
        at.update_attributes situation_date: last_date[:date], situation_date_ac_id: last_date[:ac_id]
      end
    end

    def verify_management
      if evaluative || frequency
        allocation_tag.recalculate_students_grades
      end
    end

    def set_automatic_frequency
      self.frequency_automatic = true if academic_tool_type == 'Exam'
      return nil
    end

    def update_acus
      if frequency_automatic_changed?
        # set all previously evaluated acus as evaluated_by_responsible
        academic_allocation_users.where(evaluated_by_responsible: false).where("status = #{AcademicAllocationUser::STATUS[:evaluated]} AND working_hours IS NOT NULL").update_all evaluated_by_responsible: true

        # set all not evaluated acus with automatic frequency
        academic_allocation_users.where(evaluated_by_responsible: false, working_hours: nil).where("status = #{AcademicAllocationUser::STATUS[:sent]} OR ( (grade > 0) AND (status = #{AcademicAllocationUser::STATUS[:evaluated]}))").update_all working_hours: max_working_hours, status: AcademicAllocationUser::STATUS[:evaluated]
      end

      if max_working_hours_changed?
        # update max_working_hours
        academic_allocation_users.where(evaluated_by_responsible: false).where("status = #{AcademicAllocationUser::STATUS[:evaluated]} AND working_hours IS NOT NULL").update_all working_hours: max_working_hours
      end
    end

end
