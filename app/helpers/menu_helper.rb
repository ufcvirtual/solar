module MenuHelper

  # div.mysolar_menu_group
  #   ul
  #     li.mysolar_menu_title_multiple
  #       a.mysolar_menu_title
  #       ul.submenu
  #         li.mysolar_menu_list
  #           a
  #         li.mysolar_menu_list
  #           a

  def menu
    all_profiles_ids, profiles_ids = user_session[:all_profiles], (user_session[:uc_profiles]) 
    id, current_menu = user_session[:context_uc], user_session[:menu][:current]
    context_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:context]

    menus = Menu.list_by_profile_id_and_context_id(all_profiles_ids, profiles_ids, context_id)
    divs_group, div_group_opened, previous_parent_id = [], false, 0

    if context_id == Context_Curriculum_Unit
      active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
      home_menu = {"url" => active_tab[:breadcrumb].first[:url], "parent" => "menu_home", "parent_id" => 0, "child" => nil, "parent_order" => 0, "context_id" => Context_Curriculum_Unit, "resource_id" => 11} #parent: "Inicio"
      menus.insert(0, home_menu)
    end

    menus.each_with_index do |menu, idx|
      access_controller = menu["url"].nil? ? {controller: "/#{menu["controller"]}", action: menu["action"], mid: menu['parent_id'], bread: menu['parent']}  : menu["url"]
      div_group_opened  = false if (previous_parent_id != menu['parent_id'].to_i) # quando o pai muda, outra div deve ser criada
      menu_div_id       = (menu['context_id'] == Context_Curriculum_Unit.to_s ? "menu-#{idx}-#{id}" : "menu-#{idx}-")

      unless div_group_opened # menu pai
        div_group_opened = true
        link_class = ['mysolar_menu_title', ((menu['parent_id'].to_i == current_menu.to_i and params.include?(:mid)) ? 'open_menu' : nil)].compact.join(' ')
        a_link     = ((menu['child'].nil?) ? link_to(t(menu['parent'].to_sym), access_controller, class: link_class) : %{#{t(menu['parent'].to_sym)}})
        path       = (context_id == Context_Curriculum_Unit) ? "/curriculum_units/#{id}" : URI(url_for(access_controller)).path

        divs_group[menu['parent_id'].to_i] = {
          ul: {
            li: {
              id: "menu-parent_#{menu['parent_id']}-#{id}", menu: "menu-parent_#{menu['parent_id']}-", a: a_link, ul: [], path: path
            }
          }
        }
      end # end if

      if div_group_opened and (not menu['child'].nil?) # filhos do menu pai
        access_controller[:id]    = id unless id.nil?
        access_controller[:bread] = menu['child']
        path       = (context_id == Context_Curriculum_Unit) ? "/" : URI(url_for(access_controller)).path

        divs_group[menu['parent_id'].to_i][:ul][:li][:ul] << 
          %{
            <li class="mysolar_menu_list" id="#{menu_div_id}" data-menu="menu-#{idx}-" data-path="#{path}">
              #{link_to(t(menu['child'].to_sym), access_controller)}
            </li>
          }
      end # end if

      previous_parent_id = menu['parent_id'].to_i

    end # end menu each


    return to_html(divs_group.compact, id)
  end

  private

    def to_html(divs, offer_id)
      html = ''
      html << %{<div class="mysolar_menu" data-offer=#{offer_id}>}
      divs.compact.each do |div|
        without_childs = div[:ul][:li][:ul].empty?
        li_class = ['mysolar_menu_title_', (without_childs ? 'single' : 'multiple')].join('')
        submenu  = without_childs ? '' : %{<ul class="submenu">#{div[:ul][:li][:ul].join('')}</ul>}

        html << %{
          <div class="mysolar_menu_group">
            <ul>
              <li class="#{li_class}" id="#{div[:ul][:li][:id]}" data-menu="#{div[:ul][:li][:menu]}" data-path="#{div[:ul][:li][:path]}">
                #{div[:ul][:li][:a]}
                #{submenu}
              </li>
            </ul>
          </div>
        }
      end
      html << %{</div>}
      return html
    end # end transforme_to_html

end # end module
