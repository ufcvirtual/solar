module ApplicationHelper

  def message
    [:notice,:success,:error].map {|type| %{<span class="#{type}">#{flash[type]}</span>} if flash[type] }.compact.join
  end

  def render_tabs
    tabs_opened = user_session[:tabs][:opened]

    return if tabs_opened.nil?

    tabs_opened.map { |id, name, link|
      name = name[:breadcrumb].first[:tab] || name[:breadcrumb].first[:name]

      active_tab = tabs_opened[id][:breadcrumb].first[:url][:id] rescue nil
      tab_active_class = 'mysolar_unit_active_tab' if user_session[:tabs][:active] == id

      if tabs_opened[id][:url][:context] == Context_General
        %{
          <li data-tab-context="#{Context_General}" data-tab-id="home" class="#{tab_active_class} mysolar_unit_tab general_context">
            #{link_to(name, activate_tab_path(id: id), :'aria-label' => t('tabs.access', name: name))}
          </li>
        }
      else
        %{
          <li data-tab-context="#{Context_Curriculum_Unit}" data-tab-id="#{active_tab}" class="#{tab_active_class} mysolar_unit_tab">
            #{link_to((name.truncate(30) rescue ''), activate_tab_path(id: id), :'aria-label' => t('tabs.access', name: name), :'data-tooltip'=>name)}
            #{link_to('',close_tab_path(id: id), class: 'tabs_close', id: "#{active_tab}", :'aria-label' => t('tabs.close', name: name), :'data-tooltip' => t('tabs.close', name: name), data: { confirm: t('tabs.close_confirm', name: name) })}
          </li>
        }
      end
    }.join
  end

  ## Renderiza a navegação da paginação.
  def render_pagination_bar(total_itens = "1", hash_params = nil)
    total_pages = (total_itens.to_f/Rails.application.config.items_per_page.to_f).ceil.to_i
    total_pages = 1 unless total_itens.to_i > 0

    result = ''
    if @current_page.to_i > total_pages
      @current_page = total_pages.to_s
      result << '<script>$(function() { $(\'form[name="paginationForm"]\').submit(); });</script>'
    end

    total_pages = total_pages.to_s

    result << '<form accept-charset="UTF-8" action="" method="' << request.method << '" name="paginationForm">'

    unless hash_params.nil?
      # ex: type=index&search=1 2 3
      hash_params.split("&").each do |item|
        individual_param = item.split("=")
        v = individual_param[1].nil? ? "" : individual_param[1]
        result << '<input id="' << individual_param[0] << '" name="' << individual_param[0] << '" value="' << v << '" type="hidden">'
      end
    end
    text_pagination = ' ' << @current_page << t(:navigation_of) << total_pages << ' '
    unless (@current_page.eql? "1") # voltar uma página: <<
      result << '<a class="link_navigation" onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)-1).to_s << ');$(this).parent().submit();" aria-label="(' << text_pagination.to_s << ') '<< t(:navigation_previous_page) << ((@current_page.to_i)-1).to_s << '">&lt;&lt;</a>'
    end

    result << text_pagination
    unless (@current_page.eql? total_pages) # avançar uma página: >>
      result << '<a class="link_navigation" onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)+1).to_s << ');$(this).parent().submit();" aria-label="(' << text_pagination.to_s << ') '<< t(:navigation_next_page) << ((@current_page.to_i)+1).to_s << '">&gt;&gt;</a>'
    end

    result << '<input type="hidden" id="current_page" name="current_page" value="' << @current_page << '"/>'
    result << '</form>'
  end

  ## Renderiza a seleção de turmas
  def render_group_selection(hash_params = nil)
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    profiles_ids = current_user.profiles_with_access_on('show', 'curriculum_units', nil, true)
    groups = current_user.groups(profiles_ids, Allocation_Activated, nil, nil, active_tab[:url][:id])
    # O grupo (turma) a ter seus fóruns exibidos será o grupo selecionado na aba de seleção ('selected_group')
    selected_group_id = AllocationTag.find(active_tab[:url][:allocation_tag_id]).group_id
    # Se o group_select estiver vazio, ou seja, nenhum grupo foi selecionado pelo usuário,
    # o grupo a ter seus fóruns exibidos será o primeiro grupo encontrado para o usuário em questão
    selected_group_id = groups.first.id if selected_group_id.blank?

    active_tab[:breadcrumb].first[:url][:selected_group] = Group.find(selected_group_id).get_code_name
    active_tab[:breadcrumb].first[:url][:allocation_tag_id] = active_tab[:url][:allocation_tag_id]

    result = ''
    if (groups.length > 1 && @can_select_group)
       result = "#{t(:group)}: "
       result << "<a class='btn btn_dropdown' href='#' data-dropdown= '#group-options-dropdown'> #{active_tab[:breadcrumb].first[:url][:selected_group]}"
       result << "<i class='icon-arrow-down-triangle' aria-hidden='true'></i> </a>"
       result << "<div class='dropdown dropdown-tip right' id='group-options-dropdown'>"
       result <<  "<ul class='dropdown-menu'>"
      groups.each do |g|
        class_li = selected_group_id==g.id ? 'selected' : 'null';
        link_groups = link_to g.get_code_name, select_group_path(selected_group: g.id), :'aria-label' => t('scores.index.select_group'), :class => class_li
        result << "<li role='menuitem' onclick='focusTitle();'>"+link_groups+"</li>"
      end
      result << "</ul> </div>"

    else
      result = t(:group) << ":&nbsp #{Group.find(selected_group_id).get_code_name}"
    end

    return result
  end

  def is_curriculum_unit_selected?
    not(user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:id].nil?)
  end

  def in_mysolar?
    return (params[:action] == "mysolar")
  end

  def render_json_error(error, path, default_error="general_message", message=nil)
    error_message = error == CanCan::AccessDenied ? t(:no_permission) : ((I18n.translate!("#{path}.#{error}", raise: true) rescue I18n.translate!("#{path}.#{default_error}", raise: true)) rescue t("common_between_pages.error.general_message"))
    Rails.logger.info "[ERROR] [APP] [#{Time.now}] [#{error}] [#{(message.nil? ? error_message : error.message)}]"
    render json: { success: false, alert: (message.nil? ? error_message : error.message) }, status: :unprocessable_entity
  end

  def class_css_post_unread(ual, post)
    old_posts_date =  YAML::load(File.open("config/global.yml"))[Rails.env.to_s]["posts"]["old_post_date"]
    if current_user.id == post.user_id || old_posts_date > post.created_at
        class_css = ' '
    elsif ual.nil? 
      class_css = ' new'
    elsif ual.date_last_access.nil? || ual.date_last_access < post.created_at
      class_css = ' new'
    else
      class_css = ' '
    end
  end

end
