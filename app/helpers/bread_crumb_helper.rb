module BreadCrumbHelper

  def show_breadcrumb
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]

    breadcrumb = if active_tab[:url][:context].to_i == Context_General.to_i
      active_tab[:breadcrumb] if active_tab[:breadcrumb].length > 1 # somente a aba ativa
    else
      [user_session[:tabs][:opened]['Home'][:breadcrumb].first] + active_tab[:breadcrumb]
    end

    text_bread = ''
    [breadcrumb].flatten.each_with_index do |bread, idx|
      unless bread.nil?
        link = link_to(t(bread[:name].to_sym, default: bread[:name].titleize), bread[:url])

        text_bread << '&nbsp;>&nbsp;' if idx > 0
        text_bread << %{<span data-level="#{idx}">#{link}</span>}
      end
    end

    return text_bread
  end

end
