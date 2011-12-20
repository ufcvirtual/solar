module BreadCrumbHelper

  def show_breadcrumb
    text_bread, active_tab = '', user_session[:tabs][:opened][user_session[:tabs][:active]]

    # verifica se a aba ativa é a home
    unless active_tab[:url]['type'].to_i == Tab_Type_Home.to_i
      breadcrumb = user_session[:tabs][:opened]['Home'][:breadcrumb] + active_tab[:breadcrumb]

      breadcrumb.each_with_index do |link, idx|
        unless link.nil?
          text_bread << '&nbsp;>&nbsp;' if idx > 0
          text_bread << '<span style="text-decoration: underline;">'
          text_bread << link_to(((idx == 0)? link[:name] : t(:"#{link[:name]}")), link[:url])
          text_bread << '</span>'
        end
      end
    end

    return text_bread
  end

end
