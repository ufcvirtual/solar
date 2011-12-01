module BreadCrumbHelper

  def show_breadcrumb()
    text_bread = ''
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    breadcrumb = user_session[:breadcrumb] + active_tab[:breadcrumb]
    unless breadcrumb.length == 1
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
