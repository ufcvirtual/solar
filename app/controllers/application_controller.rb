# Variaveis de sessao do usuario
# user_session {
#   :tabs => {
#     :opened => {},
#     :active => ''
#   }
# }
class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :authenticate_user! # devise
  before_filter :start_user_session

  before_filter :another_level_breadcrumb
  before_filter :set_locale, :application_context, :current_menu
  before_filter :log_access, :only => :add_tab

  # Mensagem de erro de permissão
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = t(:no_permission)
    redirect_to :controller => :home, :flash => flash
  end

  ##
  # Inicializa valores da sessao do usuario logado
  ##
  def start_user_session
    return nil unless user_signed_in?

    user_session[:tabs] = {
      :opened => {
        'Home' => {
          :breadcrumb => [],
          :url => {'type' => Tab_Type_Home}
        }
      }, :active => 'Home'
    } unless user_session.include?(:tabs)

    user_session[:breadcrumb] = [{ :name => 'Home', :url => {:controller => :application, :action => :activate_tab, :name => 'Home'} }]
  end

  ##
  # Consulta id relacionado a estudante na tabela PROFILES
  ##
  def student_profile
    prof = Profile.find_by_student(true)
    return prof.id if prof
    return ''
  end

  ###########################################
  # BREADCRUMB
  ###########################################

  ##
  # Define um novo nivel no breadcrumb da aba atual
  ##
  def another_level_breadcrumb
    same_level_for_all = 1
    user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb][same_level_for_all] = {
      :name => params[:bread], :url => params
    } if params.include?('bread')

    params.delete('bread')
    params.delete('mid')
  end

  ##
  # Recupera o contexto que esta sendo acessado
  ##
  def application_context
    return nil unless user_signed_in?
    @context, @context_param_id = Context.find(active_tab[:url]['type']).name, active_tab[:url]["id"]
  end

  ##
  # Seta o valor do menu corrente
  ##
  def current_menu
    user_session[:menu] = { :current => params[:mid] } if user_signed_in? and params.include?('mid')
  end

  ###############################
  # TABS
  ###############################

  ##
  # Modifica aba ativa
  ##
  def set_active_tab(tab_name)
    user_session[:tabs][:active] = tab_name
    # atualiza breadcrumb
    #    bread = user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb]
    #
    #    unless bread.last[:name] == tab_name
    #      user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb].delete_at(-1)
    #    end

    # verificar se existe ultimo nivel de breadcrumb e renderiza este

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
    # verifica se a aba que esta sendo acessada esta aberta
    redirect = {}
    unless user_session[:tabs][:opened].has_key?(params[:name])
      set_active_tab_to_home
      redirect = {:controller => :home}
    else
      set_active_tab(params[:name])
      if active_tab[:url]['type'] == Tab_Type_Home
        redirect = {:controller => :home}
      else
        redirect = {:controller => :curriculum_units, :action => :show, :id => active_tab[:url]['id']}
      end
    end

    redirect_to redirect, :flash => flash
  end

  ##
  # Adiciona uma aba no canto superior da interface
  ##
  def add_tab

    name_tab, type = params[:name], params[:type] # Home ou Curriculum_Unit
    id, allocation_tag_id = params[:id], params[:allocation_tag_id]

    # se estourou numero de abas, volta para mysolar
    redirect = {:controller => :home} # Tab_Type_Home

    # abre abas ate um numero limitado; atualiza como ativa se aba ja existe
    if new_tab?(name_tab)
      hash_tab = {"id" => id, "type" => type, "allocation_tag_id" => allocation_tag_id}

      # atualizando dados da sessao
      set_session_opened_tabs(name_tab, hash_tab, params)

      # redireciona de acordo com o tipo de aba
      redirect = { :controller => :curriculum_units, :action => :show, :id => id, :allocation_tag_id => allocation_tag_id } if type == Tab_Type_Curriculum_Unit

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

    redirect_to ((active_tab[:url]['type'] == Tab_Type_Curriculum_Unit) ? {:controller => :curriculum_units, :action => :show, :id => active_tab[:url]['id']} : {:controller => :home})
  end

  private

  ##
  # Verifica se existe uma aba criada com o nome passado
  ##
  def new_tab?(name_tab)
    return (user_session[:tabs][:opened].length < Max_Tabs_Open.to_i) || (user_session[:tabs][:opened].has_key?(name_tab))
  end

  ##
  # Atualiza a sessao com as abas abertas e ativas destruindo o ultimo nivel
  ##
  def set_session_opened_tabs(name_tab, hash_url, params_url)
    user_session[:tabs][:opened][name_tab] = {
      :breadcrumb => [{:name => params[:name], :url => params_url}],
      :url => hash_url
    }
    user_session[:tabs][:active] = name_tab
  end

  ##
  # Grava log de acesso a unidade curricular
  ##
  def log_access
    Log.create(:log_type => Log::TYPE[:course_access], :user_id => current_user.id, :curriculum_unit_id => params[:id]) if (params[:type] == Tab_Type_Curriculum_Unit)
  end

  ##
  # Default locale da aplicação
  ##
  def set_locale
    if user_signed_in?

      # recupera os dados de locale das configuracoes do usuario
      personal_options = PersonalConfiguration.find_by_user_id(current_user.id)

      # caso seja o primeiro acesso do usuario
      personal_options = PersonalConfiguration.new :user_id => current_user.id if personal_options.nil?

      I18n.locale = params[:locale] || personal_options.default_locale || I18n.default_locale

      # se o locale for passado pela url os dados do usuario serao alterados no base de dados
      unless params[:locale].nil?
        personal_options.default_locale = params[:locale]
        personal_options.save
      end

      # caso seja a primeira sessao do usuario
      personal_options.save if personal_options.new_record?

    else
      I18n.locale = params[:locale] || I18n.default_locale
    end
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
  # Preparando para seleção genérica de turmas
  ##
  def prepare_for_group_selection
    if params.include?('selected_group') and active_tab[:url]['type'] == Tab_Type_Curriculum_Unit
      allocation_tag_id = AllocationTag.find_by_group_id(params[:selected_group]).id
      user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] = allocation_tag_id
    end
  end

  def hold_pagination
    user_session[:current_page] = @current_page
  end

  ##
  # Retora o hash, com as informações da aba ativa
  ##
  def active_tab
    user_session[:tabs][:opened][user_session[:tabs][:active]] if user_signed_in?
  end

end
