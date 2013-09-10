class AcademicAllocation < ActiveRecord::Base
  belongs_to :academic_tool, polymorphic: true
  belongs_to :allocation_tag

  #Relacionamentos extras#
  has_many :sent_assignments
  has_many :group_assignments, dependent: :destroy

  validate :verify_assignment_offer_date_range, if: :is_assignment?

  before_save :verify_association_with_allocation_tag
  before_create :verify_uniqueness

  def is_assignment?
  	academic_tool_type.eql? 'Assignment'
  end

  # Antes de salvar, verifica se as allocations_tags passadas permitem a ferramenta em questão.
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

  # verifica se já existe uma academicAllocation com todos os dados iguais
  def verify_uniqueness 
    AcademicAllocation.where(allocation_tag_id: allocation_tag_id, academic_tool_type: academic_tool_type, academic_tool_id: academic_tool_id).empty?
  end

  private

    ## Datas da atividade devem estar no intervalo de datas da oferta
    def verify_assignment_offer_date_range
      if allocation_tag.group
        errors.add(:base, I18n.t(:final_date_smaller_than_offer, :scope => [:assignment, :notifications], :end_date_offer => allocation_tag.group.offer.end_date.to_date)) if academic_tool.schedule.end_date > allocation_tag.group.offer.end_date
      end
    end

end
