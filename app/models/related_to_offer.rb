module RelatedToOffer

  # Toda ferramenta que puder ser criada para ofertas, inclui este módulo e terá acesso à constante OFFER_PERMISSION
  OFFER_PERMISSION = true

 def self.included(base)   
    base.before_create :verify_offers
  end

  # Antes de salvar, verifica se as allocations_tags passadas são de uma oferta. Se for, permite. 
  # Caso contrário, verifica se possui acesso a outro módulo. Se possuir, deixa a verificação para ele.
  def verify_offers
    allocations_tags = (self.respond_to?(:academic_allocations) ? self.academic_allocations.map(&:allocation_tag) : [(self.allocation_tag || AllocationTag.find(self.allocation_tag_id))]).compact

    unless allocations_tags.empty?

      case
        when (not allocations_tags.map(&:offer).include?(nil))
          permission = true
        when (not allocations_tags.map(&:group).include?(nil))
          others_permissions = self.class.constants.include?(:GROUP_PERMISSION)
        when (not allocations_tags.map(&:curriculum_unit).include?(nil))
          others_permissions = self.class.constants.include?(:CURRICULUM_UNIT_PERMISSION)
        when (not allocations_tags.map(&:course).include?(nil))
          others_permissions = self.class.constants.include?(:COURSE_PERMISSION)
        else
          others_permissions = false
      end

    end

    return permission ? true : (others_permissions ? true : (raise CanCan::AccessDenied))

  end

end