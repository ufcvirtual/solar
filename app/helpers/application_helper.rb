module ApplicationHelper
  def message
		text = ""
		[:notice,:success,:error].each {|type|
			if flash[type]
				text += "<span class=\"#{type}\">#{flash[type]}</span>"
      end
		}
		text
	end

  #Ver se existe outro lugar melhor para este método.
  def render_tabs
    text = ""
    tabs = session[:opened_tabs]

    unless tabs.nil?
      tabs.each do |name, link|
        text += "<div class="
        if session[:active_tab] == name
          text += "mysolar_unit_active_tab >"
        else
          text += "mysolar_unit_tab >"
        end
        text += "<a href='/application/activate_tab?name=#{name}'>#{name}</a>"
        # se for a aba não for a home, tem 'fechar'
        if (session[:opened_tabs][name]["type"] != Tab_Type_Home)
          text += "<a href='/application/close_tab?name=#{name}' class=tabs_close></a>"
        end
        text += "</div>"
      end
    end

    return text
  end

end
