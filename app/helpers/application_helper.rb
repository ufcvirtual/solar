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
        text += "<a href='/application/active_tab?name=#{name}&l=#{link}'>#{name}</a>"
        text += "</div>"
      end
    end

    return text
  end

end
