module BreadCrumbHelper

  def show_breadcrumb
    text_bread, active_tab = '', user_session[:tabs][:opened][user_session[:tabs][:active]]

    # verifica se a aba ativa é a home
    breadcrumb = []
    if active_tab[:url]['context'].to_i == Context_General.to_i
      breadcrumb = active_tab[:breadcrumb] if active_tab[:breadcrumb].length > 1 # somente a aba ativa 
    else
      breadcrumb = [user_session[:tabs][:opened]['Home'][:breadcrumb].first] + active_tab[:breadcrumb]
    end

    breadcrumb.each_with_index do |link, idx|
        unless link.nil?
          text_bread << '&nbsp;>&nbsp;' if idx > 0
          text_bread << '<span style="text-decoration: underline;">'
          text_bread << link_to(((idx == 0)? link[:name] : t(:"#{link[:name]}")), link[:url])
          text_bread << '</span>'
        end
      end

    return text_bread
  end

end
