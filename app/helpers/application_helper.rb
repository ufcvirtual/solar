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


  #Renderiza a navegação da paginação.
  #PRECISAMOS INTERNACIONALIZAR ISSO
  def render_pagination_bar(total_itens = "1")
    #Limpando as variaveis

    #descobrindo o número total de páginas
    total_pages = (total_itens.to_f/Rails.application.config.items_per_page.to_f).ceil.to_i

#    if @current_page.to_i > total_pages
#      @current_page = total_pages.to_s
#      #redirect_to request.fullpath
#    end

    total_pages = total_pages.to_s

    result = '<form accept-charset="UTF-8" action="" method="post" name="paginationForm" style="display:inline">'

    unless (@current_page.eql? "1")# voltar uma página: <<
      result << '<a onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)-1).to_s << ');$(this).parent().submit();">&lt;&lt;</a>'
    end

    # página atual: 
    result << ' ' << @current_page << ' de ' << total_pages << ' ' #PRECISAMOS INTERNACIONALIZAR ISSO AQUI

    unless (@current_page.eql? total_pages)# avançar uma página: >>
      #result << '<a href="javascript:$(\'#current_page\').val(' << ((current_page.to_i)+1).to_s << ');$(\'#current_page\').parent().submit();">&gt;&gt;</a>'
      result << '<a onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)+1).to_s << ');$(this).parent().submit();">&gt;&gt;</a>'
    end
    
    result << ' <input name="authenticity_token" value="' << form_authenticity_token << '" type="hidden">'
    result << '<input type="hidden" id="current_page" name="current_page" value="' << @current_page << '"/>'
    
    result << '</form>'
    return result
  end

  # recupera o nome da unidade curricular em questao
  def curriculum_unit_name
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"] # recupera unidade curricular da sessao
    CurriculumUnit.find(curriculum_unit_id).name
  end
end
