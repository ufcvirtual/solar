##########
# Variaveis de sessao do usuario
# 
# user_session {
#   :current_page,
#   :menu,
#   :tabs => {
#     :opened => {
#       'name' => {
#         :breadcrumb => [],
#         :url => {}
#       }
#     },
#     :active => 'name'
#   }
# }
##########
class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :authenticate_user! # devise
  before_filter :start_user_session
  
  before_filter :set_locale, :application_context, :current_menu
  before_filter :another_level_breadcrumb
  before_filter :log_access, :only => :add_tab

  # Mensagem de erro de permissão
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = t(:no_permission)
    redirect_to :controller => :home, :flash => flash
  end

  ##
  # Inicializa valores da sessao quando o usuário se loga
  ##
  def start_user_session
    return nil unless user_signed_in?

    user_session[:tabs] = {
      :opened => {
        'Home' => {
          :breadcrumb => [ { :name => 'Home', :url => {:controller => :application, :action => :activate_tab, :name => 'Home', :context => Context_General} } ],
          :url => {'context' => Context_General}
        }
      }, :active => 'Home'
    } unless user_session.include?(:tabs)

    user_session[:menu] = { :current => nil } if user_session[:menu].blank?
  end

  ##
  # Id do perfil estudante na tabela profiles
  ##
  def student_profile
    Profile.find_by_types(Profile_Type_Student).id
  end

  ###########################################
  # BREADCRUMB
  ###########################################

  ##
  # Define um novo nivel no breadcrumb da aba atual
  ##
  def another_level_breadcrumb
    same_level_for_all = 1 # ultimo nivel, por enquanto o breadcrumb só comporta 3 níveis
    user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb][same_level_for_all] = {
      :name => params[:bread], :url => params
    } if params.include?('bread')
  end

  def clear_breadcrumb_home
    user_session[:tabs][:opened]['Home'][:breadcrumb] = [user_session[:tabs][:opened]['Home'][:breadcrumb].first]
  end

  ##
  # Recupera o contexto que esta sendo acessado
  ##
  def application_context
    return nil unless user_signed_in?
    context_id = nil
    context_id = Context_General if params.include?('action') and params['action'] == 'mysolar'
    set_tab_by_context
    @context_id = context_id || active_tab[:url]['context']
    @context_allocation_tag_id = context_id.nil? ? active_tab[:url]['id'] : nil
  end
  
  ##
  # Abre aba adequada para o contexto
  ##  
  def set_tab_by_context
    
    if user_signed_in? 
      # Aba Home para edição de dados do usuário (devise)
      set_active_tab_to_home if controller_path == "devise/registrations"
      
      # Seleciona aba de acordo com o contexto do menu
      if params.include?('mid')
        tab_context_id = active_tab[:url]['context']
        current_menu_id = params[:mid]
        
        if MenusContexts.find_all_by_menu_id_and_context_id(current_menu_id, tab_context_id).empty?
          menu_context_id = MenusContexts.find_by_menu_id(current_menu_id).context_id
     
          # Econtra a aba de mesmo contexto       
          tab_name = find_tab_by_context(menu_context_id)
      
          # Abre aba de mesmo contexto    
          set_active_tab(tab_name)
        end
      end
    end
  end

  ##
  # Seta o valor do menu corrente
  ##
  def current_menu
    user_session[:menu] = { :current => params[:mid] } if user_signed_in? and params.include?('mid')
    user_session[:menu] = { :current => nil } if (params.include?('context'))
  end

  ###############################
  # ABAS
  ###############################

  ##
  # Modifica aba ativa
  ##
  def set_active_tab(tab_name)
    user_session[:tabs][:active] = tab_name
  end

  ##
  # Seta aba ativa para Home
  ##
  def set_active_tab_to_home
    set_active_tab('Home')
  end

  ##
  # Exibe conteudo da aba ativa
  ##
  def activate_tab
    clear_breadcrumb_home
    # verifica se a aba que esta sendo acessada esta aberta
    redirect = {:controller => :home}
    unless user_session[:tabs][:opened].has_key?(params[:name])
      set_active_tab_to_home # o usuário é redirecionado para o Home caso a aba não exista
    else
      set_active_tab(params[:name])
      # dentro da aba, podem existir links abertos
      redirect = active_tab[:breadcrumb].last[:url] if active_tab[:url]['context'].to_i == Context_Curriculum_Unit
    end

    redirect_to redirect, :flash => flash
  end

  ##
  # Adiciona uma aba ao conjunto de abas abertas
  # Obs.: A quantidade de abas abertas é limitada
  ##
  def add_tab
    clear_breadcrumb_home
    tab_name, context_id = params[:name], params[:context].to_i # Home, Curriculum_Unit ou outro nao mapeado
    id, allocation_tag_id = params[:id], params[:allocation_tag_id]

    # se estourou numero de abas, volta para mysolar
    redirect = {:controller => :home} # Context_General

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if opened_or_new_tab?(tab_name)
      hash_tab = {"id" => id, "context" => context_id, "allocation_tag_id" => allocation_tag_id}
      set_session_opened_tabs(tab_name, hash_tab, params)

      # redireciona de acordo com o tipo de aba
      redirect = { :controller => :curriculum_units, :action => :show, :id => id, :allocation_tag_id => allocation_tag_id } if context_id == Context_Curriculum_Unit
    end

    redirect_to redirect, :flash => flash
  end

  ##
  # Fecha abas
  ##
  def close_tab
    tab_name = params[:name]
    set_active_tab_to_home if user_session[:tabs][:active] == tab_name
    user_session[:tabs][:opened].delete(tab_name)

    controller_curriculum_unit = {:controller => :curriculum_units, :action => :show, :id => active_tab[:url]['id']}
    redirect = ((active_tab[:url]['context'] == Context_Curriculum_Unit) ? controller_curriculum_unit : {:controller => :home})
    redirect_to redirect, :flash => flash
  end

  ##
  # Retora o hash, com as informações da aba ativa
  ##
  def active_tab
    user_session[:tabs][:opened][user_session[:tabs][:active]] if user_signed_in?
  end

  private

  ##
  # Verifica se existe uma aba criada com o nome passado
  ##
  def opened_or_new_tab?(tab_name)
    (user_session[:tabs][:opened].has_key?(tab_name)) or (user_session[:tabs][:opened].length < Max_Tabs_Open.to_i)
  end

  ##
  # Atualiza a sessao com as abas abertas e ativas destruindo o ultimo nivel
  ##
  def set_session_opened_tabs(tab_name, hash_url, params_url)
    user_session[:tabs][:opened][tab_name] = {
      :breadcrumb => [{:name => params[:name], :url => params_url}],
      :url => hash_url
    }
    set_active_tab tab_name
  end

  ##
  # Grava log de acesso a unidade curricular
  ##
  def log_access
    Log.create(:log_type => Log::TYPE[:course_access], :user_id => current_user.id, :curriculum_unit_id => params[:id]) if (params[:context].to_i == Context_Curriculum_Unit)
  end

  ##
  # Default locale da aplicação
  ##
  def set_locale
    # se o usuario estiver logado e passar locale nos parametros eh salvo
    if user_signed_in?
      personal_options = PersonalConfiguration.find_by_user_id(current_user.id)

      # configuracoes pessoais sao criadas se nao existir
      if personal_options.nil?
        personal_options = PersonalConfiguration.new(:user_id => current_user.id, :default_locale => (params[:locale] || I18n.default_locale) )
        personal_options.save
      elsif params.include?('locale')
        personal_options.default_locale = params[:locale]
        personal_options.save
      end
      locale = params[:locale] || personal_options.default_locale
    else
      locale = params[:locale] || I18n.default_locale
    end

    I18n.locale = locale
  end

  ##
  # Preparando o uso da paginação
  ##
  def prepare_for_pagination
    @current_page = user_session[:current_page]
    user_session[:current_page] = nil

    @current_page = params[:current_page] if @current_page.nil?
    @current_page = "1" if @current_page.nil?
  end

  ##
  # Parametros de locale para paginas externas
  ##
  def default_url_options(options={})
    params.include?('locale') ? {:locale => params[:locale]} : {}
  end

  ##
  # Preparando para seleção genérica de turmas
  ##
  def prepare_for_group_selection
    if active_tab[:url]['context'] == Context_Curriculum_Unit
      if !params.include?('selected_group')
        curriculum_unit_id = active_tab[:url]['id']
        params[:selected_group] = CurriculumUnit.find_user_groups_by_curriculum_unit(curriculum_unit_id, current_user.id).first.id
      end
      allocation_tag_id = AllocationTag.find_by_group_id(params[:selected_group]).id
      user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] = allocation_tag_id
    end
  end

  def hold_pagination
    user_session[:current_page] = @current_page
  end

  def after_sign_in_path_for(resource_or_scope)
    pages_index_url
  end

  def after_update_path_for(resource)
    '/home'
  end
  
  ##
  # Encontra uma aba com o contexto passado
  ##
  def find_tab_by_context(context_id)
    user_session[:tabs][:opened].each { |tab|    
      if (tab[1][:url]['context'].to_i == context_id.to_i)
        return tab[0]
      end
    }
  end






 def is_class_responsible?
    query = <<SQL
      SELECT DISTINCT 
        FROM profiles AS profile ON profile.type = #{Profile_Type_Class_Responsible} and profile.status = TRUE
        JOIN allocations AS allocation ON allocation.profile_id = profile.id and allocation.user_id = #{current_user.id} and allocation.status = 1
SQL

    raise "#{Discussion.find_by_sql(query)}"

#and allocation_tag_id = 

  end






end
