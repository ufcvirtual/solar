module RelatedToOffer

  OFFER_PERMISSION = true

 def self.included(base)   
    base.before_create :verify_offers
  end

  # verifica se pode salvar
  def verify_offers
    others_permissions = self.class.constants.include?(:GROUP_PERMISSION) or self.class.constants.include?(:COURSE_PERMISSION) or self.class.constants.include?(:CURRICULUM_UNIT_PERMISSION)

    if self.respond_to?(:academic_allocations) # foi feita a adaptação para academic_allocations
      permission = (not self.academic_allocations.map(&:allocation_tag).map(&:offer).include?(nil))
    else # ainda não foi feita a adaptação
      permission = (not self.allocation_tag.try(:offer).nil?)
    end

    return permission ? true : (others_permissions ? true : (raise CanCan::AccessDenied))
  end

end