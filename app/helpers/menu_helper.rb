module MenuHelper

  # Lista os menus de todos os perfis
  def create_menu_list(profile_id, context = 'geral', id = nil, current_menu = nil)

    # Recupera a lista de menus
    menus = Menu.list_by_profile_id_and_context(profile_id, context)

    # variaveis de controle
    html_menu, previous_father_id, first_iteration = '', 0, false

    # classes de css utilizadas pelos menus
    class_menu_div_topo = 'mysolar_menu_group'
    class_menu_title = 'mysolar_menu_title'
    class_menu_list = 'mysolar_menu_list'

    html_menu_group = []

    # percorrer todos os registros
    menus.each do |menu|

      access_controller = {
        :controller => menu["controller"],
        :action => menu["action"],
        :mid => menu['father_id'],
        :bread => nil
      }

      # verifica se o menu pai foi modificado para gerar um novo menu
      unless previous_father_id == menu["father_id"].to_i

        # coloca as divs anteriores em uma nova div
        html_menu_group << "<div class='#{class_menu_div_topo}'>#{html_menu}</div>" if first_iteration # verifica se ja entrou aqui

        # para um menu pai ser um link ele nao deve ter filhos
        if !menu["resource_id"].nil? && menu['child'].nil?
          access_controller[:bread] = t(menu['father'].to_sym)
          link = link_to("#{t(menu['father'].to_sym)}", access_controller)
        elsif !menu["link"].nil?
          link = "<a href='#{menu['link']}'>#{t(menu['father'].to_sym)}</a>"
        else
          # verifica menu corrente
          if (menu['father_id'] == current_menu)
            link = "<a href='#' class='open_menu'>#{t(menu['father'].to_sym)}</a>"
          else
            link = "<a href='#'>#{t(menu['father'].to_sym)}</a>"
          end
        end

        # menus pai tbm podem ter links diretamente para funcionalidades
        html_menu = "<div id='father_#{menu['father_id']}' class='#{class_menu_title}'>#{link}</div>"

        # indica primeira iteracao
        first_iteration = true
      end

      # verifica se existe filho para imprimir
      access_controller[:id] = id unless id.nil?

      unless menu['child'].nil?
        access_controller[:bread] = t(menu['child'].to_sym)
        html_menu << "<div class='#{class_menu_list}'>" << link_to("#{t(menu['child'].to_sym)}", access_controller) << "</div>"
      end

      # sempre atualiza o previous_father
      previous_father_id = menu['father_id'].to_i
    end

    html_menu_group << "<div class='#{class_menu_div_topo}'>#{html_menu}</div>"
    return html_menu_group.join('') # fechando a ultima div aberta
  end

end
