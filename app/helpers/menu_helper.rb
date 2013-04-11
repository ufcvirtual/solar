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

  def menu(profile_id, context_id, id = nil, current_menu = nil)
    menus = Menu.list_by_profile_id_and_context_id(profile_id, context_id)
    divs_group, div_group_opened, previous_parent_id = [], false, 0

    menus.each do |menu|
      # raise "#{menu}"
      access_controller = {:controller => "/#{menu["controller"]}", :action => menu["action"], :mid => menu['parent_id'], :bread => menu['parent']}
      div_group_opened = false if (previous_parent_id != menu['parent_id'].to_i) # quando o pai muda, outra div deve ser criada

      unless div_group_opened # menu pai
        div_group_opened = true
        link_class = ['mysolar_menu_title', ((menu['parent_id'].to_i == current_menu.to_i and params.include?(:mid)) ? 'open_menu' : nil)].compact.join(' ')
        a_link = ((menu['child'].nil?) ? link_to(t(menu['parent'].to_sym), access_controller, :class => link_class) : %{<a href="#" class="#{link_class}">#{t(menu['parent'].to_sym)}</a>})

        divs_group[menu['parent_id'].to_i] = {
          :ul => {
            :li => {
              :id => "parent_#{menu['parent_id']}", :a => a_link, :ul => []
            }
          }
        }
      end # end if

      if div_group_opened and (not menu['child'].nil?) # filhos do menu pai
        access_controller[:id] = id unless id.nil?
        access_controller[:bread] = menu['child']
        divs_group[menu['parent_id'].to_i][:ul][:li][:ul] << 
          %{
            <li class="mysolar_menu_list">
              #{link_to(t(menu['child'].to_sym), access_controller)}
            </li>
          }
      end # end if

      previous_parent_id = menu['parent_id'].to_i

    end # end menu each

    return to_html(divs_group)
  end

  private

    def to_html(divs)
      html = ''
      divs.compact.each do |div|
        without_childs = div[:ul][:li][:ul].empty?
        li_class = ['mysolar_menu_title_', (without_childs ? 'single' : 'multiple')].join('')
        submenu = without_childs ? '' : %{<ul class="submenu">#{div[:ul][:li][:ul].join('')}</ul>}

        html << %{
          <div class="mysolar_menu_group">
            <ul>
              <li class="#{li_class}" id="#{div[:ul][:li][:id]}">
                #{div[:ul][:li][:a]}
                #{submenu}
              </li>
            </ul>
          </div>
        }
      end
      return html
    end # end transforme_to_html

end # end module
