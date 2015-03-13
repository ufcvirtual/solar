class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user
    can do |action, object_class, object, options = []|
      have_permission?(user, [action].flatten, object_class, object, options)
    end # can
  end

  private

    def have_permission?(user, action, object_class, object, options)
      if options.include?(:accepts_general_profile) # action accepts general profile
        allocation_tags_ids = user.allocation_tags_ids_with_access_on([action], object_class.to_s.underscore.pluralize, false, true) # if has nil, exists an allocation with allocation_tag_id nil
        admin_or_general_profile = user.admin? || allocation_tags_ids.include?(nil)
      end

      if (options.include?(:on) && admin_or_general_profile) || !(options.include?(:on)) # on allocation_tags
        have_permission_access?(user, action, object_class, object)
      else
        have_permission_on_allocation_tags?(user, action, object_class, options[:on].split(' ').flatten.map(&:to_i), !!options[:read], !!options[:any])
      end

    end # have permission?

    ## a verificacao de permissao para leitura considera todas as at relacionadas
    def have_permission_on_allocation_tags?(user, action, object_class, allocation_tags, read = false, any = false)
      if any
        ( allocation_tags & user.allocation_tags_ids_with_access_on(alias_action(action.first), object_class.to_s.underscore.pluralize, read) ).any?
      else
        ( allocation_tags - user.allocation_tags_ids_with_access_on(alias_action(action.first), object_class.to_s.underscore.pluralize, read) ).empty?
      end
    end # have permission on allocation tags

    def have_permission_access?(user, action, object_class, object)
      ## perfis do usuario que podem realizar acao
      profiles = user.profiles.joins(:resources).where(resources: { action: alias_action(action.first), controller: object_class.to_s.underscore.pluralize })
      have     = !(profiles.to_ary.empty?) # tem permissao para acessar acao


      return false unless have # nao tem permissao de realizar acao
      return true if have && object.nil? # tem permissao de realizar acao na classe e objeto nao e passado

      ## se é ou está relacionado diretamente com usuario
      return true if object_class == User && (object.id == user.id || profiles.select('permissions_resources.per_id').map(&:per_id).include?('f')) # qndo o usuario tem permissoes de ver apenas seus dados
      return true if object.respond_to?(:user) && !(object.user.nil?) && (object.user.id == user.id || alias_action(:read))

      ## diferenciar tipo das actions (ler/modificar)
        ## se for pra ler, pode ser em qualquer nivel
        ## se for modificar, verifica associacoes apenas pra baixo

      ## usuario relacionado com o objeto atraves das allocation_tags
      if object.respond_to?(:allocation_tag) || (object_class != User && object.respond_to?(:allocation_tags))
        object_allocation_tags = (object.respond_to?(:allocation_tag) ? [object.allocation_tag.id] : object.allocation_tags.map(&:id))
        all_or_lower = (alias_action(action.last).select { |a| [:create, :update, :destroy].include?(a) }.empty?) ? {} : {lower: true} # modificar objeto?
        at_of_user   = user.allocation_tags.joins(:allocations).where(allocations: { profile_id: profiles.map(&:id), status: Allocation_Activated.to_i }).collect!{|at| at.related(all_or_lower)}.flatten.uniq ## allocations do usuario com perfil para executar a acao
        match        = !((at_of_user & object_allocation_tags).empty?) # at em comum entre o usuario e o objeto

        return match
      end # respond to

      ## no caso de allocation_tag
      return true if object.respond_to?(:allocations) && !(object.allocations.where(user_id: user.id, profile_id: profiles, status: Allocation_Activated.to_i).empty?)
      return false # default e nao ter permissao
    end # have permission access?

    ## com alias, evitamos criacoes de muitos resources (ex. permissao :create, para :new e :create)
    def alias_action(action)
      return case action
        when :show, :read
          [:show, :read]
        when :new, :create
          [:new, :create]
        when :edit, :update
          [:edit, :update]
        else
          [action] # index, list e outros
      end
    end # alias action

end
