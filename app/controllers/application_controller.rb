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
  before_filter :set_locale, :start_user_session, :application_context, :current_menu, :another_level_breadcrumb

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to home_path, alert: t(:no_permission)
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    # logar: exception.message
    respond_to do |format|
      format.html { redirect_to home_path, alert: t(:object_not_found), status: :not_found }
      format.json { render json: {msg: t(:object_not_found)}, status: :not_found }
    end
  end

  def start_user_session
    return unless user_signed_in?

    user_session[:tabs] = {
      opened: {
        'Home' => {
          breadcrumb: [{ name: 'Home', url: activate_tab_path(name: 'Home', context: Context_General)}],
          url: {'context' => Context_General}
        }
      }, active: 'Home'
    } unless user_session.include?(:tabs)

    user_session[:menu] = { current: nil } if user_session[:menu].blank?
  end

  def another_level_breadcrumb
    same_level_for_all = 1 # ultimo nivel, por enquanto o breadcrumb só comporta 3 níveis
    user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb][same_level_for_all] = { name: params[:bread], url: params } if params[:bread].present?
  end

  def application_context
    return nil unless user_signed_in?

    set_tab_by_context

    is_mysolar  = (params.include?('action') and params['action'] == 'mysolar')
    @context_id = is_mysolar ? Context_General : active_tab[:url]['context']
    @context_uc = is_mysolar ? nil : active_tab[:url]['id']
    @profiles   = (active_tab[:url]['context'].to_i == Context_Curriculum_Unit) ? current_user.profiles.map(&:id).join(',') : current_user.profiles_activated(true).join(',')
  end

  def current_menu
    user_session[:menu] = { current: params[:mid] } if user_signed_in? and params[:mid].present?
    user_session[:menu] = { current: nil } if params[:context].present?
  end

  def set_active_tab(tab_name)
    user_session[:tabs][:active] = tab_name
  end

  def set_active_tab_to_home
    set_active_tab('Home')
  end

  def active_tab
    user_session[:tabs][:opened][user_session[:tabs][:active]] if user_signed_in?
  end

  def prepare_for_pagination
    @current_page = user_session[:current_page]
    user_session[:current_page] = nil

    @current_page = params[:current_page] if @current_page.nil?
    @current_page = "1" if @current_page.nil?
  end

  def hold_pagination
    user_session[:current_page] = @current_page
  end

  def prepare_for_group_selection
    return unless active_tab[:url]['context'] == Context_Curriculum_Unit.to_i

    # verifica se o grupo foi passado e se é um grupo válido
    unless params[:selected_group].present? and !!(allocation_tag_id_group = AllocationTag.find_by_group_id(params[:selected_group]).try(:id))
      allocation_tag = AllocationTag.find(active_tab[:url]['allocation_tag_id'])
      params[:selected_group] = allocation_tag.group_id
      allocation_tag_id_group = (allocation_tag.group_id.nil?) ? Group.find_all_by_curriculum_unit_id_and_user_id(active_tab[:url]['id'], current_user.id).first.allocation_tag.id : allocation_tag.id
    end

    user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] = allocation_tag_id_group
  end

  def after_sign_in_path_for(resource_or_scope)
    pages_path
  end

  def after_update_path_for(resource)
    '/home'
  end

  def set_locale
    if user_signed_in?
      personal_options = PersonalConfiguration.find_or_create_by_user_id(current_user.id, default_locale: (params[:locale] || I18n.default_locale))
      personal_options.update_attributes(default_locale: params[:locale]) if (params[:locale].present? and params[:locale].to_s != personal_options.default_locale.to_s)
      params[:locale]  = personal_options.default_locale
    end

    I18n.locale = params[:locale] || I18n.default_locale
  end

  ## Parametros de locale para paginas externas
  def default_url_options(options={})
    params.include?('locale') ? {:locale => params[:locale]} : {}
  end

  private

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

    def opened_or_new_tab?(tab_name)
      (user_session[:tabs][:opened].has_key?(tab_name)) or (user_session[:tabs][:opened].length < Max_Tabs_Open.to_i)
    end

    def set_session_opened_tabs(tab_name, hash_url, params_url)
      user_session[:tabs][:opened][tab_name] = { breadcrumb: [{name: params[:name], url: params_url}], url: hash_url }
      set_active_tab tab_name
    end

    def find_tab_by_context(context_id)
      user_session[:tabs][:opened].each { |tab| return tab[0] if (tab[1][:url]['context'].to_i == context_id.to_i) }
    end

end
