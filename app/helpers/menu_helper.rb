module MenuHelper

  # parents: {
  #   1: {
  #     name: "link",
  #     children: [
  #       {contexts: [1], bread: bread, link: link1},
  #       {contexts: [1,2], bread: bread, link: link2},
  #     ]
  #   }
  # },
  # singles: [
  #   {contexts: [1,2], bread: bread, link: link},
  # ]
  def menu_list
    context_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:context]
    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:allocation_tag_id]

    menus = current_user.menu_list({contexts: [context_id], allocation_tag_id: allocation_tag_id})

    menu_list = {
      singles: [],
      parents: {}
    }

    menus.each_with_index do |menu, idx|
      contexts = menu.contexts.pluck(:id)
      menu_item_link = link_to(t(menu.name), url_for({controller: "/#{menu.resource.controller}", action: menu.resource.action,
        bread: menu.name, contexts: contexts.join(',')}), onclick: 'focusTitle();', onkeypress: 'focusTitle();', onkeydown: 'click_on_keypress(event, this);', class: menu.parent.nil? ? 'mysolar_menu_title' : '')
      menu_item = {contexts: contexts, bread: menu.name, link: menu_item_link}

      if menu.parent.nil?
        menu_list[:singles] << menu_item
      else
        menu_list[:parents][menu.parent_id] = {name: t(menu.parent.name), children: []} unless menu_list[:parents].has_key?(menu.parent_id)
        menu_list[:parents][menu.parent_id][:children] << menu_item
      end
    end # menu list - each

    to_html(menu_list)
  end

  private

    def to_html(menu_list)
      parents = menu_list[:parents].map do |p_id, father|
        children = father[:children].map { |kid| create_link(kid, p_id, 'list') }
        %{
          <div class="mysolar_menu_group">
            <ul>
              <li class="mysolar_menu_title_multiple">
                #{father[:name]}
                <ul class="submenu">
                  #{children.join}
                </ul>
              </li>
            </ul>
          </div>
        }
      end # parents each

      singles = menu_list[:singles].map do |single|
        %{
          <div class="mysolar_menu_group">
            <ul>
              #{create_link(single)}
            </ul>
          </div>
        }
      end # singles each

      [parents, singles].compact.join
    end

    def create_link(link, parent_id = nil, type = 'single')
      li_class = (type == 'single') ? 'mysolar_menu_title_single' : 'mysolar_menu_list'
      %{
        <li class="#{li_class}" data-contexts="#{link[:contexts]}" data-menu-bread="#{link[:bread]}">
          #{link[:link]}
        </li>
      }
    end

end # end module
