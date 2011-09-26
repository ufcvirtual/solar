module MenuHelper

  # Lista os menus de todos os perfis
  def create_menu_list(profile_id, context = 'geral', id = nil, current_menu = nil)

    # Recupera a lista de menus
    menus = Menu.list_by_profile_id_and_context(profile_id, context)

    # variaveis de controle
    html_menu, previous_parent_id, first_iteration = '', 0, false

    # classes de css utilizadas pelos menus
    class_menu_div_topo = 'mysolar_menu_group'
    class_menu_title = 'mysolar_menu_title'
    class_menu_list = 'mysolar_menu_list'

    html_menu_group = []
puts "\n\n\n\n\n\n\n\n\n\n\n\n\n\n*******************************"
    # percorrer todos os registros
    menus.each do |menu|
puts "\n\n\n\n\nmenu:\n#{menu}\nprevious_parent_id: #{previous_parent_id}"
      access_controller = {
        :controller => menu["controller"],
        :action => menu["action"],
        :mid => menu['parent_id'],
        :bread => nil
      }

      # verifica se o menu pai foi modificado para gerar um novo menu
      unless previous_parent_id == menu["parent_id"].to_i

        html_menu << "</ul>" if first_iteration #[fechando1]

        if !(!menu["resource_id"].nil? && menu['child'].nil?)
          html_menu << "</li></ul>" #[fechando2]
        elsif !menu["link"].nil?
          html_menu << "</ul>" #[fechando3]
        elsif (menu['parent_id'] == current_menu)
          html_menu << "</li></ul>" #[fechando4]
        else
          html_menu << "</li></ul>" #[fechando5]
        end

        # coloca as divs anteriores em uma nova div
        html_menu_group << "<div class='#{class_menu_div_topo}'>#{html_menu}</div>" if first_iteration # verifica se ja entrou aqui

        # para um menu pai ser um link ele nao deve ter filhos
        if !menu["resource_id"].nil? && menu['child'].nil?
          access_controller[:bread] = menu['parent']
          link = "<li id='parent_#{menu['parent_id']}'>" << link_to("#{t(menu['parent'].to_sym)}", access_controller, :class =>  class_menu_title) << "</li>"
puts ">> 1: #{link}" #messages
        elsif !menu["link"].nil?
          link = "<li><a href='#{menu['link']}'>#{t(menu['parent'].to_sym)}</a></li>"
puts ">> 2: #{link}"
        else
          # verifica menu corrente
          if (menu['parent_id'] == current_menu)
            link = "<li><a href='#' class='#{class_menu_title} open_menu'>#{t(menu['parent'].to_sym)}</a><ul class='submenu'>"
puts ">> 3: #{link}"
          else
            link = "<li id='parent_#{menu['parent_id']}'><a href='#' class='#{class_menu_title}'>#{t(menu['parent'].to_sym)}</a><ul class='submenu'>"
puts ">> 4: #{link}" #menu pai
          end
        end

        # menus pai tbm podem ter links diretamente para funcionalidades
        #html_menu = "<ul id='parent_#{menu['parent_id']}' class='#{class_menu_title}'>#{link}"
        html_menu = "<ul>#{link}"

        # indica primeira iteracao
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
    html_menu << "</ul>" #[fechando]
    
puts "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
    html_menu_group << "<div class='#{class_menu_div_topo}'>#{html_menu}</div>"
    return html_menu_group.join('') # fechando a ultima div aberta
  end

end
