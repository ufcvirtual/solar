module MenuHelper

  # retorna o menu de acordo com o perfil do usuario
  def create_menu_list(profiles_id, context = 'geral', id = nil)
    # consulta para recuperar os dados do menu
    query = "
      WITH cte_menus AS (
       SELECT t1.id    AS father_id,
              t1.order AS father_order,
              t1.name  AS father,
              t2.id    AS child_id,
              t2.order AS child_order,
              t2.name  AS child,
              t2.resources_id
         FROM menus             AS t1                           -- menu pai
         JOIN menus             AS t2 ON (t2.father_id = t1.id) -- menu filho
         JOIN permissions_menus AS t3 ON (t3.menus_id = t2.id) -- verifica permissoes aos menus filhos
        WHERE t2.status = TRUE AND t3.profiles_id IN (#{profiles_id}) -- permissoes para os menus filhos
      ), -- menus filhos com permissoes associadas
      --
      cte_all_fathers AS (
          SELECT t1.id    AS father_id,
                 t1.order AS father_order,
                 t1.name  AS father,
                 t3.child_order,
                 t3.child_id,
                 t3.child,
                 COALESCE(t3.resources_id, t1.resources_id) AS resources_id, -- resource do filho, senao do pai
                 COALESCE(t4.name, 'geral') AS context,
                 t1.link
            FROM menus             AS t1 -- recuperando todos os menus-pai
            JOIN permissions_menus AS t2 ON (t2.menus_id = t1.id AND t1.father_id IS NULL) -- verifica permissoes aos menus pais
       LEFT JOIN cte_menus         AS t3 ON (t3.father_id = t1.id)
       LEFT JOIN contexts          AS t4 ON (t4.id = t1.contexts_id)
           WHERE t1.status = TRUE AND t2.profiles_id IN (#{profiles_id}) -- permissoes para os menus pais
      )
      SELECT t1.father_id,
             t1.father,
             t1.father_order,
             t1.child,
             t1.child_order,
             t1.context,
             t1.resources_id,
             t2.controller,
             t2.action,
             t1.link
        FROM cte_all_fathers  AS t1
   LEFT JOIN resources        AS t2 ON (t2.id = t1.resources_id)
       WHERE (t1.context = 'geral' OR t1.context = '#{context}')
         AND ((t1.resources_id IS NOT NULL AND t2.status = TRUE) OR (t1.resources_id IS NULL AND t1.child IS NULL)) -- verifica se o registro eh um pai ou nao
       ORDER BY t1.father_order, t1.child_order;"

    menus = ActiveRecord::Base.connection.select_all query

    # variaveis de controle
    html_menu, previous_father_id, open_div_menu_child = '', 0, false

    # classes de css utilizadas pelos menus
    class_menu_title = 'mysolar_menu_title'
    class_menu_list = 'mysolar_menu_list'

    # percorrer todos os registros
    menus.each do |menu|

      access_controller = {:controller => menu["controller"], :action => menu["action"]}

      # verifica se o menu pai foi modificado para gerar um novo menu
      unless previous_father_id == menu["father_id"].to_i
        # verifica se foi aberto alguma div de menu filho
        html_menu << "</div>" if open_div_menu_child # fecha div do menu filho

        # para um menu pai ser um link ele nao deve ter filhos
        if (menu["resources_id"] != nil && menu['child'] == nil)
          link = link_to("#{menu['father']}", access_controller)
        else
          link = "<a href='#'>#{menu['father']}</a>"
        end

        # menus pai tbm podem ter links diretamente para funcionalidades
        html_menu << "<h3 class='#{class_menu_title}'>#{link}</h3>"

        # print dos menus filhos
        html_menu << "<div class='#{class_menu_list}'>"
        open_div_menu_child = true
      end
      # verifica se existe filho para imprimir
      access_controller[:id] = id unless id.nil?
      html_menu << link_to("#{menu['child']}", access_controller) << "<br />" unless menu['child'].nil?

      # sempre atualiza o previous_father
      previous_father_id = menu['father_id'].to_i
    end

    return html_menu << "</div>" # fechando a ultima div aberta
  end

  def users_profiles(users_id = 0)
    profiles = Allocation.find(:all, :select => "DISTINCT profiles_id AS id", :conditions => ["users_id = ?", users_id]).collect{|p| p.id}
    return 0 unless profiles.length > 0
    profiles.join(',')
  end

end
