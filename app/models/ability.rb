class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new # guest user

    # realizar uma consulta filtrando pelas tabelas onde o usuario vai acessar
    # offers, groups, etc...

    unless user.id.nil?
      query = "
          SELECT t3.controller,
                 t3.action,
                 CASE WHEN t3.per_id = TRUE THEN
                     translate(
                        array_agg(
                            DISTINCT
                            CASE t3.controller
                                WHEN 'group' THEN t5.groups_id
                                WHEN 'offer' THEN t5.offers_id
                                WHEN 'curriculum_unit' THEN t5.curriculum_units_id
                                WHEN 'course' THEN t5.courses_id
                                ELSE t4.users_id
                            END)::text, '{}', '[]'
                     )
                 ELSE NULL
                 END         AS objetos
            FROM profiles    AS t1
            JOIN permissions AS t2 ON t2.profiles_id = t1.id
            JOIN resources   AS t3 ON t3.id = t2.resources_id
            JOIN allocations AS t4 ON t4.profiles_id = t1.id
            JOIN allocation_tags AS t5 ON t5.id = t4.allocation_tags_id
           WHERE t4.users_id = #{user.id}
           GROUP BY t3.controller, t3.action, t3.per_id
           ORDER BY 1, 2;"

      conn = ActiveRecord::Base.connection
      permissoes = conn.select_all query

      # setando as permissoes
      permissoes.each do |permissao|
        permissao['objetos'] = (eval(permissao['objetos']) unless permissao['objetos'].nil?) || nil
        can permissao["action"].to_sym, permissao["controller"].capitalize.constantize do |classe|
          # verifica se o usuario esta tentando acessar um objeto permitido
          permissao['objetos'].nil? || permissao['objetos'].include?(classe.id)# objetos permitidos sao listados em um array
        end
      end

    else
      # permissoes para usuarios nao logados
      can [:create], User
    end

    # Users
#    can [:create, :update, :mysolar, :update_photo, :pwd_recovery], User do |usuario|
#      usuario.try(:id) == user.id
#    end
#
#    #    # Offers
#    can :showoffersbyuser, Offer

    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
