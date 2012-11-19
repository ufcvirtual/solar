class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user
    can do |action, object_class, object|
      have_permission?(user, action, object_class, object)
    end # can
  end

  private

    def have_permission?(user, action, object_class, object)
      ## perfis do usuario que podem realizar acao
      profiles = user.profiles.joins(:resources).where(resources: {action: alias_action(action), controller: object_class.to_s.underscore << 's'})
      have     = not(profiles.to_ary.empty?) # tem permissao para acessar acao

      return false unless have # nao tem permissao de realizar acao
      return true if have and object.nil? # tem permissao de realizar acao na classe e objeto nao e passado

      ## se é ou está relacionado diretamente com usuario
      return true if object_class == User and (object.id == user.id or profiles.select("permissions_resources.per_id").map(&:per_id).include?('f')) # qndo o usuario tem permissoes de ver apenas seus dados
      return true if object.respond_to?(:user_id) and object.user_id == user.id

      ## diferenciar tipo das actions (ler/modificar)
        ## se for pra ler, pode ser em qualquer nivel
        ## se for modificar, verifica associacoes apenas pra baixo

      ## usuario relacionado com o objeto atraves das allocation_tags
      if object.respond_to?(:allocation_tag)
        at_all_or_lower = (alias_action(action).select { |a| [:create, :update].include?(a) }.empty?) ? {all: true} : {lower: true} # modificar objeto?
        at_of_user      = user.allocations.where(profile_id: profiles, status: Allocation_Activated.to_i).map(&:allocation_tag).compact.map {|at| at.related(at_all_or_lower) }.flatten.compact.uniq ## allocations do usuario com perfil para executar a acao
        match           = not((at_of_user & [object.allocation_tag.id]).empty?) # at em comum entre o usuario e o objeto

        return match
      end

      ## no caso de allocation_tag
      return true if object.respond_to?(:allocations) and not(object.allocations.where(user_id: user.id, profile_id: profiles, status: Allocation_Activated.to_i).empty?)
      return false # default e nao ter permissao
    end # have permission

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
