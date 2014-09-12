class AcademicAllocation < ActiveRecord::Base

  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag

  # Assignment
  has_many :sent_assignments, dependent: :destroy
  has_many :group_assignments, dependent: :destroy

  # Discussion
  has_many :discussion_posts, class_name: 'Post', dependent: :destroy

  # Chat
  belongs_to :chat_room, foreign_key: 'academic_tool_id'

  has_many :chat_messages, dependent: :destroy
  has_many :participants, class_name: 'ChatParticipant', inverse_of: :academic_allocation, dependent: :destroy

  accepts_nested_attributes_for :participants, allow_destroy: true, reject_if: proc { |attributes| attributes['allocation_id'] == '0' }

  attr_accessible :participants_attributes, :allocation_tag_id, :academic_tool_id, :academic_tool_type

  validate :verify_assignment_offer_date_range, if: :is_assignment?

  before_save :verify_association_with_allocation_tag
  before_validation :verify_uniqueness

  # LessonModule
  before_destroy :move_lessons_to_default, if: :is_lesson_module?

  def is_assignment?
    academic_tool_type.eql? 'Assignment'
  end
  
  def is_lesson_module?
    academic_tool_type.eql? 'LessonModule'
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
        (new_record? or (allocation_tag_id_changed? or academic_tool_type_changed? or academic_tool_id_changed?)) and 
        AcademicAllocation.where(allocation_tag_id: allocation_tag_id, academic_tool_type: academic_tool_type, academic_tool_id: academic_tool_id).any?
      )

      errors.add(:base, I18n.t(:uniqueness, scope: [:activerecord, :errors])) if error
    end

    # Métodos destinados ao Assignment

    ## datas da atividade devem estar no intervalo de datas da oferta
    def verify_assignment_offer_date_range
      if allocation_tag.group and academic_tool.schedule.end_date.to_date > (offer_end_date = allocation_tag.group.offer.end_date)
        message = I18n.t('assignment.notifications.final_date_smaller_than_offer', end_date_offer: I18n.l(offer_end_date)).to_s
        errors.add(:base, message)
        raise "academic_allocation #{message}"
      end
    end

    # métodos destinados ao Lesson Module

    def move_lessons_to_default
      lesson_module = LessonModule.joins(:academic_allocations).where({is_default: true, academic_allocations: {allocation_tag_id: allocation_tag_id}})
      academic_tool.lessons.update_all(lesson_module_id: lesson_module) unless lesson_module.empty?
    end

end
