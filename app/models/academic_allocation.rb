class AcademicAllocation < ActiveRecord::Base
  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag

  #Relacionamentos extras#
  
  #Assignment
  has_many :sent_assignments, dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :discussion_posts, class_name: "Post", dependent: :destroy

  validate :verify_assignment_offer_date_range, if: :is_assignment?

  before_save :verify_association_with_allocation_tag
  before_validation :verify_uniqueness

  #LessonModule
  before_destroy :move_lessons_to_default, if: :is_lesson_module?

  def is_assignment?
    academic_tool_type.eql? 'Assignment'
  end
  
  def is_lesson_module?
    academic_tool_type.eql? 'LessonModule'
  end  

  private

    ## Antes de salvar, verifica se as allocations_tags passadas permitem a ferramenta em questão.
    def verify_association_with_allocation_tag
      model_name = academic_tool_type.constantize

      case
        when (not allocation_tag.try(:group).nil?)
          permission = model_name.const_defined?(:GROUP_PERMISSION)
        when (not allocation_tag.try(:offer).nil?)
          permission = model_name.const_defined?(:OFFER_PERMISSION)
        when (not allocation_tag.try(:curriculum_unit).nil?)
          permission = model_name.const_defined?(:CURRICULUM_UNIT_PERMISSION)
        when (not allocation_tag.try(:course).nil?)
          permission = model_name.const_defined?(:COURSE_PERMISSION)
        else
          permission = false
      end
      return permission ? true : (raise ActiveRecord::AssociationTypeMismatch)
    end


    ## verifica se já existe uma AcademicAllocation com todos os dados iguais
    def verify_uniqueness
      errors.add(:base, I18n.t(:uniqueness, scope: [:activerecord, :errors])) unless AcademicAllocation.where(allocation_tag_id: allocation_tag_id, academic_tool_type: academic_tool_type, academic_tool_id: academic_tool_id).empty?
    end

    # Métodos destinados ao Assignment

    ## Datas da atividade devem estar no intervalo de datas da oferta
    def verify_assignment_offer_date_range
      if allocation_tag.group and academic_tool.schedule.end_date.to_date > allocation_tag.group.offer.end_date.to_date
        message = I18n.t(:final_date_smaller_than_offer, scope: [:assignment, :notifications], end_date_offer: I18n.l(allocation_tag.group.offer.end_date.to_date)).to_s

        errors.add(:base, message)
        raise "academic_allocation #{message}"
      end
    end


    # Métodos destinados ao Lesson Module  
    def move_lessons_to_default
      lesson_module = LessonModule.find(academic_tool_id)
      not_exist_default = LessonModule.joins(:academic_allocations).where({is_default: true,academic_allocations: {allocation_tag_id: allocation_tag_id}}).empty?
      unless  not_exist_default
        lesson_module.lessons.update_all(lesson_module_id: LessonModule.joins(:academic_allocations).where({is_default: true,academic_allocations: {allocation_tag_id: allocation_tag_id}}))
      end     
    end


end
