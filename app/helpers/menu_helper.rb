module MenuHelper

  def create_menu_list(profile_id, context_id, id = nil, current_menu = nil)
    menus = Menu.list_by_profile_id_and_context_id(profile_id, context_id)
    html_menu, previous_parent_id, first_iteration = '', 0, false

    # classes de css utilizadas pelos menus
    class_menu_div_topo = 'mysolar_menu_group'
    class_menu_title = 'mysolar_menu_title'
    class_menu_list = 'mysolar_menu_list'

    html_menu_group = []

    # percorrer todos os registros
    menus.each do |menu|

      access_controller = {
        :controller => "/#{menu["controller"]}",
        :action => menu["action"],
        :mid => menu['parent_id'],
        :bread => nil
      }

      # verifica se o menu pai foi modificado para gerar um novo menu
      unless previous_parent_id == menu['parent_id'].to_i
        html_menu << "</ul>" if first_iteration

        if !(!menu['resource_id'].nil? && menu['child'].nil?)
          html_menu << "</li></ul>"
        elsif !menu['link'].nil?
          html_menu << "</ul>"
        elsif (menu['parent_id'] == current_menu)
          html_menu << "</li></ul>"
        else
          html_menu << "</li></ul>"
        end

        # coloca as divs anteriores em uma nova div
        html_menu_group << "<div class='#{class_menu_div_topo}'>#{html_menu}</div>" if first_iteration # verifica se ja entrou aqui

        # para um menu pai ser um link ele nao deve ter filhos
        if !menu['resource_id'].nil? && menu['child'].nil?
          access_controller[:bread] = menu['parent']
          style_single = "mysolar_menu_title_single_active" if menu['parent_id'] == current_menu and params.include?('mid')
          link = "<li class='mysolar_menu_title_single #{style_single}' id='parent_#{menu['parent_id']}'>" << link_to("#{t(menu['parent'].to_sym)}", access_controller, :class =>  class_menu_title) << "</li>"
        elsif !menu["link"].nil?
          link = "<li><a href='#{menu['link']}'>#{t(menu['parent'].to_sym)}</a></li>"
        else
          # verifica menu corrente
          if (menu['parent_id'] == current_menu)
            link = "<li class='mysolar_menu_title_multiple'><a href='#' class='#{class_menu_title} open_menu'>#{t(menu['parent'].to_sym)}</a><ul class='submenu'>"
          else
            link = "<li id='parent_#{menu['parent_id']}' class='mysolar_menu_title_multiple'><a href='#' class='#{class_menu_title}'>#{t(menu['parent'].to_sym)}</a><ul class='submenu'>"
          end
        end

        html_menu = "<ul>#{link}" # menus pai tbm podem ter links diretamente para funcionalidades
        first_iteration = true
      end

      # verifica se existe filho para imprimir
      access_controller[:id] = id unless id.nil?

      unless menu['child'].nil?
        access_controller[:bread] = menu['child']
        html_menu << "<li class='#{class_menu_list}'>" << link_to("#{t(menu['child'].to_sym)}", access_controller) << "</li>"
      end

      # sempre atualiza o previous_parent
      previous_parent_id = menu['parent_id'].to_i
    end

    html_menu << "</ul>"
    html_menu_group << "<div class='#{class_menu_div_topo}'>#{html_menu}</div>"
    return html_menu_group.join('') # fechando a ultima div aberta
  end

end
