class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user
    can do |action, object_class, object|
      have_permission?(user, action, object_class, object)
    end # end can
  end

  private

  def have_permission?(user, action, object_class, object)
    profiles = user.profiles.joins(:resources).where(resources: {action: alias_action(action), controller: object_class.to_s.underscore << 's'})
    have = (not profiles.empty?)

    return false unless have # nao tem permissao de acessar funcionalidade
    return true if have and object.nil? # nao verifica objeto

    ## se é ou está relacionado diretamente com usuario
    return true if (object_class == User and object.id == user.id)
    return true if object.respond_to?(:user_id) and object.user_id == user.id

    ## diferenciar no tipo das actions
      ## se for pra ler, pode ser em qualquer nivel
      ## se for modificar, verifica associacoes apenas pra baixo

    ## usuario relacionado com o objeto por allocation_tag
    if object.respond_to?(:allocation_tag)
      at_all_or_lower = (alias_action(action).select {|a| a == :create or a == :update}.empty?) ? {all: true} : {lower: true} # modificar objeto?
      return true unless Allocation.where(allocation_tag_id: object.allocation_tag.related(at_all_or_lower), profile_id: profiles, user_id: user.id, status: Allocation_Activated.to_i).empty?
    end

    return false

  end # have permission

  ## evitando criacao de muitos resources com alias
  def alias_action(action)
    return case action
      when :index, :show, :read
        [:index, :show, :read]
      when :new, :create
        [:new, :create]
      when :edit, :update
        [:edit, :update]
      else
        [action]
    end
  end

  # def profiles_of_user_has_permission_to_access?(user, action, object_class)

  # # def has_permission_to_access?(user, action, object_class, object)
  #   user.profiles.joins(:resources).where(resources: {action: action, controller: object_class.to_s.underscore << 's'})
  # end

  # def user_have_permission_to?(user, object, profile_id)
  #   return true if (object.respond_to?(:user_id) and object.user_id == user.id)

  #   ## usuario está associado às uma das associacoes por belongs_to
  #   object.class.reflect_on_all_associations(:belongs_to).each do |class_related|
  #     return true if (object.respond_to?(class_related.name) and object.send(class_related.name).respond_to?(:user_id) and (object.send(class_related.name).user_id == user.id))
  #   end

  #   ## associacoes por allocation_tag
  #   if object.respond_to?(:allocation_tag)
  #     user_allocations_tag = user.allocations.where(profile_id: profile_id.to_i, status: Allocation_Activated.to_i).map(&:allocation_tag)
  #     allocation_tag       = object.send(:allocation_tag)

  #     ## se o usuario já está ligado diretamente à allocation_tag ou por meio da hierarquia
  #     return true if (user_allocations_tag.include?(allocation_tag) or (not (user_allocations_tag.map(&:id) & allocation_tag.related(upper: true)).empty?))
  #   end

  #   ## ligada a allocation diretamente
  #   return true if (object.respond_to?(:allocations) and (not object.send(:allocations).where(user_id: user.id, profile_id: profile_id.to_i, status: Allocation_Activated.to_i).empty?))
  #   return false
  # end

end
