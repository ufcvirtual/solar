module MenuHelper

  def create_menu_list(profile_id, context_id, id = nil, current_menu = nil)
    menus = Menu.list_by_profile_id_and_context_id(profile_id, context_id)
    html_menu, previous_parent_id, first_iteration = '', 0, false

    # classes de css utilizadas pelos menus
    class_menu_div_topo, class_menu_title, class_menu_list = %w(mysolar_menu_group mysolar_menu_title mysolar_menu_list)
    html_menu_group = []

    is_link_father_with_no_childs = false

    # raise "#{menus}"
    menus.each do |menu|

      access_controller = {
        :controller => "/#{menu["controller"]}",
        :action => menu["action"],
        :mid => menu['parent_id'],
        :bread => nil
      }

      # verifica se o menu pai muda para gerar um novo menu
      unless previous_parent_id.to_i == menu['parent_id'].to_i
        html_menu << "</ul>" if first_iteration

        if (not menu['link'].nil?)
          html_menu << "</ul>"
        elsif (not is_link_father_with_no_childs)
          html_menu << "</li></ul>"
        end

        is_link, is_not_a_child = (not menu['resource_id'].nil?), menu['child'].nil?
        is_link_father_with_no_childs = (is_link and is_not_a_child)

        # mysolar_menu_group
          # ul
            # li
              # a
              # ul.submenu

        # mysolar_menu_group
          # ul
            # li
              #a


        # coloca as divs anteriores em uma nova div
        html_menu_group << %{<div class="#{class_menu_div_topo}">#{html_menu}</div>} if first_iteration # verifica se ja entrou aqui

        # para um menu pai ser um link ele nao deve ter filhos
        if is_link_father_with_no_childs
          access_controller[:bread] = menu['parent']
          style_single = "mysolar_menu_title_single_active" if (menu['parent_id'] == current_menu and params.include?('mid'))
          link = 
            %{
              <li class="mysolar_menu_title_single #{style_single}" id="parent_#{menu['parent_id']}">
                #{link_to("#{t(menu['parent'].to_sym)}", access_controller, :class => class_menu_title)}
              </li>
            }
          # link << link_to("#{t(menu['parent'].to_sym)}", access_controller, :class => class_menu_title)
          # link << "</li>"
        elsif (not menu["link"].nil?)
          link = %{<li><a href="#{menu['link']}">#{t(menu['parent'].to_sym)}</a></li>}
        else
          if (menu['parent_id'] == current_menu) # mesmo pai
            link = 
              %{
                <li class="mysolar_menu_title_multiple">
                  <a href="#" class="#{class_menu_title} open_menu">#{t(menu['parent'].to_sym)}</a>
                  <ul class="submenu">
              }
          else
            link =
              %{
                <li class="mysolar_menu_title_multiple" id="parent_#{menu['parent_id']}">
                  <a href="#" class="#{class_menu_title}">#{t(menu['parent'].to_sym)}</a>
                  <ul class="submenu">
              }
          end
        end

        html_menu = "<ul>#{link}" # menu pai com link direto para funcionalidades
        first_iteration = true
      end

      access_controller[:id] = id unless id.nil? # verifica se existe filho para imprimir

      unless is_not_a_child # eh um filho
        access_controller[:bread] = menu['child']
        html_menu <<
          %{
            <li class="#{class_menu_list}">
              #{link_to("#{t(menu['child'].to_sym)}", access_controller)}
            </li>
          }
      end

      previous_parent_id = menu['parent_id'].to_i # sempre atualiza
    end # menu each

    html_menu << "</ul>"
    html_menu_group << %{<div class="#{class_menu_div_topo}">#{html_menu}</div>}

# raise "#{html_menu_group.join('')}"

    return html_menu_group.join('')

  end # end crate menu list

end # end module
