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
                                WHEN 'group' THEN t5.group_id
                                WHEN 'offer' THEN t5.offer_id
                                WHEN 'curriculum_unit' THEN t5.curriculum_unit_id
                                WHEN 'course' THEN t5.course_id
                                ELSE t4.user_id
                            END)::text, '{}', '[]'
                     )
                 ELSE NULL
                 END         AS objects
            FROM profiles    AS t1
            JOIN permissions_resources AS t2 ON t2.profile_id = t1.id
            JOIN resources             AS t3 ON t3.id = t2.resource_id
            JOIN allocations           AS t4 ON t4.profile_id = t1.id
            LEFT JOIN allocation_tags       AS t5 ON t5.id = t4.allocation_tag_id
           WHERE t4.user_id = #{user.id}
           GROUP BY t3.controller, t3.action, t2.per_id
           ORDER BY 1, 2;"

      permissions = ActiveRecord::Base.connection.select_all query

      # setando as permissoes
      permissions.each do |permission|
        permission['objects'] = (eval(permission['objects']) unless permission['objects'].nil?) || nil
        can permission["action"].to_sym, capitalize_controller_name(permission["controller"]) do |classe|
          # verifica se o usuario esta tentando acessar um objeto permitido
          permission['objects'].nil? || permission['objects'].include?(classe.id) # objetos permitidos sao listados em um array
        end
      end
    else
      # permissoes para usuarios nao logados
      can [:create, :pwd_recovery], User
    end
  end

  private

  # mapeia da forma 'curriculum_unit' para 'CurriculumUnit'
  def capitalize_controller_name(word)
    r = ''
    word = word.slice(0, word.length-1) if word[-1] == "s" # retira o s do final dos nomes dos controllers
    word.split('_').each {|w| r << w.capitalize}
    r.constantize
  end

end