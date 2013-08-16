module RelatedToCurriculumUnit

  # Toda ferramenta que puder ser criada para ucs, inclui este módulo e terá acesso à constante CURRICULUM_UNIT_PERMISSION
  CURRICULUM_UNIT_PERMISSION = true

 def self.included(base)   
    base.before_create :verify_curriculum_units
  end

  # Antes de salvar, verifica se as allocations_tags passadas são de ucs. Se for, permite. 
  # Caso contrário, verifica se possui acesso a outro módulo. Se possuir, deixa a verificação para os demais.
  def verify_curriculum_units
    allocations_tags = (self.respond_to?(:academic_allocations) ? self.academic_allocations.map(&:allocation_tag) : [(self.allocation_tag || AllocationTag.find(self.allocation_tag_id))]).compact

    unless allocations_tags.empty?

      case
        when (not allocations_tags.map(&:curriculum_unit).include?(nil))
          permission = true
        when (not allocations_tags.map(&:offer).include?(nil))
          others_permissions = self.class.constants.include?(:OFFER_PERMISSION)
        when (not allocations_tags.map(&:course).include?(nil))
          others_permissions = self.class.constants.include?(:COURSE_PERMISSION)
        when (not allocations_tags.map(&:group).include?(nil))
          others_permissions = self.class.constants.include?(:GROUP_PERMISSION)
        else
          others_permissions = false
      end

    end
    
    return permission ? true : (others_permissions ? true : (raise CanCan::AccessDenied))

  end

end