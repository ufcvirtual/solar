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
                 CASE WHEN t2.per_id = TRUE THEN
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
            JOIN permissions_resources AS t2 ON t2.profiles_id = t1.id
            JOIN resources   AS t3 ON t3.id = t2.resources_id
            JOIN allocations AS t4 ON t4.profiles_id = t1.id
            JOIN allocation_tags AS t5 ON t5.id = t4.allocation_tags_id
           WHERE t4.users_id = #{user.id}
           GROUP BY t3.controller, t3.action, t2.per_id
           ORDER BY 1, 2;"

      permissoes = ActiveRecord::Base.connection.select_all query

      # setando as permissoes
      permissoes.each do |permissao|
        permissao['objetos'] = (eval(permissao['objetos']) unless permissao['objetos'].nil?) || nil
        can permissao["action"].to_sym, capitalize_controller_name(permissao["controller"]) do |classe|
          # verifica se o usuario esta tentando acessar um objeto permitido
          permissao['objetos'].nil? || permissao['objetos'].include?(classe.id) # objetos permitidos sao listados em um array
        end
      end

      # Permissões para usuário sem Profile
      can [:mysolar, :update, :update_photo], User, :id => user.id
      can :showoffersbyuser, Offer
    else
      # permissoes para usuarios nao logados
      can [:create, :pwd_recovery], User
    end
  end

  private

  # mapeia da forma 'curriculum_unit' para 'CurriculumUnit'
  def capitalize_controller_name(word)
    r = ''
    word.split('_').each {|w| r << w.capitalize}
    r.constantize
  end

end
