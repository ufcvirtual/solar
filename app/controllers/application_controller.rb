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

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to({:controller => :home}, :alert => t(:no_permission))
  end

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

  def student_profile
    Profile.find_by_types(Profile_Type_Student).id
  end

  ###########################################
  # BREADCRUMB
  ###########################################

  def another_level_breadcrumb
    same_level_for_all = 1 # ultimo nivel, por enquanto o breadcrumb só comporta 3 níveis
    user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb][same_level_for_all] = {
      :name => params[:bread], :url => params
    } if params.include?('bread')
  end

  def clear_breadcrumb_home
    user_session[:tabs][:opened]['Home'][:breadcrumb] = [user_session[:tabs][:opened]['Home'][:breadcrumb].first]
  end

  def application_context
    return nil unless user_signed_in?

    set_tab_by_context

    is_mysolar = (params.include?('action') and params['action'] == 'mysolar')
    @context_id = is_mysolar ? Context_General : active_tab[:url]['context']
    @context_uc = is_mysolar ? nil : active_tab[:url]['id']

    # recuperando profiles do usuario logado dependendo do contexto
    if active_tab[:url]['context'].to_i == Context_Curriculum_Unit
      related = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id']).join(',')
      @profiles = current_user.profiles_on_allocation_tag(related, only_id = true).join(',')
    else
      @profiles = current_user.profiles_activated(only_id = true).join(',')
    end
  end

  def current_menu
    user_session[:menu] = { :current => params[:mid] } if user_signed_in? and params.include?('mid')
    user_session[:menu] = { :current => nil } if (params.include?('context'))
  end

  ###############################
  # ABAS
  ###############################

  def set_tab_by_context
    if user_signed_in? 
      set_active_tab_to_home if controller_path == "devise/registrations" # Aba Home para edição de dados do usuário (devise)
      
      # Seleciona aba de acordo com o contexto do menu
      if params.include?('mid')
        tab_context_id = active_tab[:url]['context']
        current_menu_id = params[:mid]
        
        if MenusContexts.find_all_by_menu_id_and_context_id(current_menu_id, tab_context_id).empty?
          menu_context_id = MenusContexts.find_by_menu_id(current_menu_id).context_id
          tab_name = find_tab_by_context(menu_context_id)
          set_active_tab(tab_name)
        end
      end
    end
  end

  def set_active_tab(tab_name)
    user_session[:tabs][:active] = tab_name
  end

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

      redirect = { :controller => :curriculum_units, :action => :home, :id => id, :allocation_tag_id => allocation_tag_id } if context_id == Context_Curriculum_Unit
    end

    redirect_to redirect, :flash => flash
  end

  def close_tab
    tab_name = params[:name]
    set_active_tab_to_home if user_session[:tabs][:active] == tab_name
    user_session[:tabs][:opened].delete(tab_name)

    controller_curriculum_unit = {:controller => :curriculum_units, :action => :home, :id => active_tab[:url]['id']}
    redirect = ((active_tab[:url]['context'] == Context_Curriculum_Unit) ? controller_curriculum_unit : {:controller => :home})
    redirect_to redirect, :flash => flash
  end

  def active_tab
    user_session[:tabs][:opened][user_session[:tabs][:active]] if user_signed_in?
  end

  def user_related_to_assignment?
    related_allocation_tags     = AllocationTag.find_related_ids(Assignment.find(params[:assignment_id]).allocation_tag_id)
    related_allocations_to_user = Allocation.where(:allocation_tag_id => related_allocation_tags, :user_id => current_user.id) unless related_allocation_tags.empty?
    user_related = true unless related_allocation_tags.empty? or related_allocations_to_user.empty?
    if user_related
      return true 
    else
      no_permission_redirect
      return false
    end
  end

  private

  def opened_or_new_tab?(tab_name)
    (user_session[:tabs][:opened].has_key?(tab_name)) or (user_session[:tabs][:opened].length < Max_Tabs_Open.to_i)
  end

  def set_session_opened_tabs(tab_name, hash_url, params_url)
    user_session[:tabs][:opened][tab_name] = {
      :breadcrumb => [{:name => params[:name], :url => params_url}],
      :url => hash_url
    }
    set_active_tab tab_name
  end

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
      # Variável que armazena o valor do id da turma da allocation_tag atual 
      # (que varia de acordo com a unidade curricular e a seleção de turmas)
      allocation_tag_group = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
      unless params.include?('selected_group')
        # se não existir nenhuma turma nos parâmetros, verifica se há alguma turma na allocation_tag
        if allocation_tag_group.blank?
          # se não houver, armazena como a turma a ser selecionado a primeira turma disponível para o usuário
          curriculum_unit_id = active_tab[:url]['id']
          params[:selected_group] = CurriculumUnit.find_user_groups_by_curriculum_unit(curriculum_unit_id, current_user.id).first.id
        else
          # se houver, armazena a turma da allocation_tag
          params[:selected_group] = allocation_tag_group
        end
      end
      # atualiza o valor da allocation_tag para a referente à turma selecionada
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

  def find_tab_by_context(context_id)
    user_session[:tabs][:opened].each { |tab|    
      if (tab[1][:url]['context'].to_i == context_id.to_i)
        return tab[0]
      end
    }
  end
  
  protected

  def no_permission_redirect
    redirect_to({:controller => :home}, :alert => t(:no_permission))
  end

end
