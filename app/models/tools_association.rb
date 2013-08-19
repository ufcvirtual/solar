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
    allocations_tag = (self.respond_to?(:allocation_tag_id) ? AllocationTag.find(self.allocation_tag_id) : self.allocation_tag )
    case
      when (not allocations_tag.try(:group).nil?)
        permission = self.class.const_defined?(:GROUP_PERMISSION)
      when (not allocations_tag.try(:offer).nil?)
        permission = self.class.const_defined?(:OFFER_PERMISSION)
      when (not allocations_tag.try(:curriculum_unit).nil?)
        permission = self.class.const_defined?(:CURRICULUM_UNIT_PERMISSION)
      when (not allocations_tag.try(:course).nil?)
        permission = self.class.const_defined?(:COURSE_PERMISSION)
      else
        permission = false
    end

    return permission ? true : (raise ActiveRecord::AssociationTypeMismatch)
  end

end