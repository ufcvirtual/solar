module ToolsAssociation

  # Toda ferramenta terá uma constante referente ao que ela tem relação. 
  # Por exemplo, um chat pode ser criado apenas para turmas, portanto possui apenas
  # a constante GROUP_PERMISSION definida.

  def self.included(base)   
    base.before_save :verify_relation
  end

  # Antes de salvar, verifica se as allocations_tags passadas são de turmas. Se for, permite. 
  # Caso contrário, verifica se possui acesso a outro módulo. Se possuir, deixa a verificação para ele.
  def verify_relation
    allocations_tags = (self.respond_to?(:academic_allocations) ? self.academic_allocations.map(&:allocation_tag) : [
      (self.respond_to?(:allocation_tag_id) ? AllocationTag.find(self.allocation_tag_id) : self.allocation_tag )
    ]).compact

    unless allocations_tags.empty?

      case
        when (not allocations_tags.map(&:group).include?(nil))
          permission = self.class.const_defined?(:GROUP_PERMISSION)
        when (not allocations_tags.map(&:offer).include?(nil))
          permission = self.class.const_defined?(:OFFER_PERMISSION)
        when (not allocations_tags.map(&:curriculum_unit).include?(nil))
          permission = self.class.const_defined?(:CURRICULUM_UNIT_PERMISSION)
        when (not allocations_tags.map(&:course).include?(nil))
          permission = self.class.const_defined?(:COURSE_PERMISSION)
        else
          permission = false
      end

    end

    return permission ? true : (raise ActiveRecord::AssociationTypeMismatch)

  end

end