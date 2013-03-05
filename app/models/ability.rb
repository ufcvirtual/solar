class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user
    can do |action, object_class, object, options = []|
      have_permission?(user, action, object_class, object, options)
    end # can
  end

  private

    def have_permission?(user, action, object_class, object, options)
      if options.include?(:on) # on allocation_tags
        return (have_permission_on_allocation_tags?(user, options[:on].flatten.map(&:to_i), !!options[:read]) and have_permission_access?(user, action, object_class, object))
      else
        return have_permission_access?(user, action, object_class, object)
      end
    end # have permission?

    ## a verificacao de permissao para leitura considera todas as at relacionadas
    def have_permission_on_allocation_tags?(user, allocation_tags, read = false)
      # raise "#{read}"
      (user.allocation_tags.uniq.map { |at| read ? at.related : at.related({lower: true})
        }.flatten.compact.uniq & allocation_tags).sort == allocation_tags.sort
    end # have permission on allocation tags

    def have_permission_access?(user, action, object_class, object)
      ## perfis do usuario que podem realizar acao
      profiles = user.profiles.joins(:resources).where(resources: {action: alias_action(action), controller: object_class.to_s.underscore.pluralize})
      have     = not(profiles.to_ary.empty?) # tem permissao para acessar acao

      return false unless have # nao tem permissao de realizar acao
      return true if have and object.nil? # tem permissao de realizar acao na classe e objeto nao e passado

      ## se é ou está relacionado diretamente com usuario
      return true if object_class == User and (object.id == user.id or profiles.select("permissions_resources.per_id").map(&:per_id).include?('f')) # qndo o usuario tem permissoes de ver apenas seus dados
      return true if object.respond_to?(:user) and not(object.user.nil?) and object.user.id == user.id
      # return true if object.respond_to?(:user_id) and object.user_id == user.id

      ## diferenciar tipo das actions (ler/modificar)
        ## se for pra ler, pode ser em qualquer nivel
        ## se for modificar, verifica associacoes apenas pra baixo

      ## usuario relacionado com o objeto atraves das allocation_tags
      if object.respond_to?(:allocation_tag)
        all_or_lower = (alias_action(action).select { |a| [:create, :update].include?(a) }.empty?) ? {all: true} : {lower: true} # modificar objeto?
        at_of_user   = user.allocations.where(profile_id: profiles, status: Allocation_Activated.to_i).map(&:allocation_tag).compact.map {|at| at.related(all_or_lower) }.flatten.compact.uniq ## allocations do usuario com perfil para executar a acao
        match        = not((at_of_user & [object.allocation_tag.id]).empty?) # at em comum entre o usuario e o objeto

        return match
      end # respond to

      ## no caso de allocation_tag
      return true if object.respond_to?(:allocations) and not(object.allocations.where(user_id: user.id, profile_id: profiles, status: Allocation_Activated.to_i).empty?)
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
