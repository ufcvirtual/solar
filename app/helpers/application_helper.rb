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

  # Ver se existe outro lugar melhor para este método.
  def render_tabs
    text = ""
    tabs_opened = user_session[:tabs][:opened]
    tab_active_name = user_session[:tabs][:active]

    unless tabs_opened.nil?
      tabs_opened.each do |name, link|
        text << "<li class="
        text << ((tab_active_name == name) ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'") << ">"
        text << "<a href='/application/activate_tab?name=#{name}'>#{name}</a>"
        text << "<a href='/application/close_tab?name=#{name}' class='tabs_close'></a>" if (tabs_opened[name][:url]['type'] != Tab_Type_Home)
        text << "</li>"
      end
    end

    return text
  end

  # Renderiza a navegação da paginação.
  def render_pagination_bar(total_itens = "1", hash_params = nil)
    #Limpando as variaveis

    #descobrindo o número total de páginas
    total_pages = (total_itens.to_f/Rails.application.config.items_per_page.to_f).ceil.to_i
    total_pages = 1 unless total_itens.to_i > 0

    result = ''
    if @current_page.to_i > total_pages
      @current_page = total_pages.to_s
      result << '<script>$(function() {  $(\'form[name="paginationForm"]\').submit();  });</script>'
    end

    total_pages = total_pages.to_s

    result << '<form accept-charset="UTF-8" action="" method="' << request.method << '" name="paginationForm" style="display:inline">'

    if !hash_params.nil?
      # ex: type=index&search=1 2 3
      hash_params.split("&").each { |item|
        individual_param = item.split("=")
        v = individual_param[1].nil? ? "" : individual_param[1]
        result << '<input id="' << individual_param[0] << '" name="' << individual_param[0] << '" value="' << v << '" type="hidden">'
      }
    end

    unless (@current_page.eql? "1")# voltar uma página: <<
      result << '<a class="link_navigation" onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)-1).to_s << ');$(this).parent().submit();">&lt;&lt;</a>'
    end

    # página atual:
    result << ' ' << @current_page << t(:navigation_of) << total_pages << ' '

    unless (@current_page.eql? total_pages)# avançar uma página: >>
      #result << '<a href="javascript:$(\'#current_page\').val(' << ((current_page.to_i)+1).to_s << ');$(\'#current_page\').parent().submit();">&gt;&gt;</a>'
      result << '<a class="link_navigation" onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)+1).to_s << ');$(this).parent().submit();">&gt;&gt;</a>'
    end

    result << ' <input name="authenticity_token" value="' << form_authenticity_token << '" type="hidden">'
    result << '<input type="hidden" id="current_page" name="current_page" value="' << @current_page << '"/>'

    result << '</form>'

    return result
  end

  ##
  # Renderiza a seleção de turmas
  ##
  def render_group_selection(hash_params = nil)
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]

    groups = CurriculumUnit.find_user_groups_by_curriculum_unit(active_tab[:url]["id"], current_user.id)

    if (groups.length > 1)
      result = '<form accept-charset="UTF-8" action="" method="' << request.method << '" name="groupSelectionForm" style="display:inline">'
      result <<  t(:group) << ":&nbsp"
      result << select_tag(
        :selected_group,
        options_from_collection_for_select( groups, :id, :code_semester, AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id),
        #{:onchange => "$(this).parent().submit();"}#Versao SEM AJAX
        {:onchange => "reloadContentByForm($(this).parent());"}#Versao AJAX
      )

      unless hash_params.nil?
        # ex: type=index&search=1 2 3
        hash_params.split("&").each { |item|
          individual_param = item.split("=")
          v = individual_param[1].nil? ? "" : individual_param[1]
          result << '<input id="' << individual_param[0] << '" name="' << individual_param[0] << '" value="' << v << '" type="hidden">'
        }
      end

      result << ' <input name="authenticity_token" value="' << form_authenticity_token << '" type="hidden">'
      result << '</form>'
    else
      result =  t(:group) << ":&nbsp #{groups[0].code_semester}"
    end

    return result
  end

  ##
  # Recupera o nome da unidade curricular em questao
  ##
  def curriculum_unit_name
    CurriculumUnit.find(active_tab[:url]['id']).name
  end

  ##
  # Verifica se uma unidade curricular já foi selecionada
  ##
  def curriculum_unit_selected?
    return !user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['id'].nil?
  end

end
