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
        link = link_to(t((bread[:name].to_sym rescue nil), default: (bread[:name].titleize rescue nil)), bread[:url])

        text_bread << '&nbsp;>&nbsp;' if idx > 0
        text_bread << %{<span data-level="#{idx}">#{link}</span>}
      end
    end

    return text_bread
  end

  def show_breadcrumb_title
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    breadcrumb = active_tab[:breadcrumb]
    
    text_bread = []
    [breadcrumb].flatten.each_with_index do |bread, idx|
      unless bread.nil?
        text_bread << t((bread[:name].to_sym rescue nil), default: (bread[:name].titleize rescue nil))
        text_bread <<  bread[:url][:selected_group] rescue nil
      end
    end

    ['Solar', text_bread.compact].compact.join(' - ')
  end

  def set_title(page_title)
    provide(:title, ['Solar', page_title].join(' - '))
  end

end
