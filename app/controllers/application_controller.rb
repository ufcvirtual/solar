##########
# Variaveis de sessao do usuario
#
# user_session {
#   :current_page,
#   :menu,
#   :tabs => {
#     :active => 'name',
#     :opened => {
#       'name' => {
#         :breadcrumb => [],
#         :url => {}
#       }
#     }
#   }
# }
##########

class ApplicationController < ActionController::Base

  include ApplicationHelper

  protect_from_forgery

  before_filter :authenticate_user!, except: [:verify_cpf, :api_download] # devise
  before_filter :set_locale, :start_user_session, :current_menu_context, :another_level_breadcrumb, :init_xmpp_im

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html {
        begin
          active_tab[:breadcrumb].delete_at(-1) if active_tab[:breadcrumb].count > 1 # not home
          raise 'error' if request.referer == request.original_url
          redirect_to :back, alert: t(:no_permission)
        rescue # ActionController::RedirectBackError
          redirect_to home_path, alert: t(:no_permission)
        end
      }
      format.json { render json: {msg: t(:no_permission), alert: t(:no_permission)}, status: :unauthorized }
      format.js { render js: "flash_message('#{t(:no_permission)}', 'alert');" }
    end
  end

  if Rails.env != 'development'
    rescue_from ActiveRecord::RecordNotFound do |exception|
      # logar: exception.message
      respond_to do |format|
        format.html { redirect_to home_path, alert: t(:object_not_found) }
        format.json { render json: { msg: t(:object_not_found)}, status: :not_found }
      end
    end

    rescue_from ActiveRecord::AssociationTypeMismatch do |exception|
      respond_to do |format|
        format.html { redirect_to home_path, alert: t(:not_associated) }
        format.json { render json: { msg: t(:not_associated)}, status: :unauthorized }
      end
    end

    rescue_from ActionView::Template::Error do |exception|
      respond_to do |format|
        format.html { redirect_to((user_signed_in? ? home_path : login_path), alert: t(:cant_build_page)) }
        format.json { render json: { msg: t(:cant_build_page)}, status: :unauthorized }
      end
    end
  end

  def start_user_session
    return unless user_signed_in?

    user_session[:tabs] = {
      opened: {
        'Home' => {
          breadcrumb: [{ name: 'Home', url: activate_tab_path(name: 'Home', context: Context_General) }],
          url: { context: Context_General }
        }
      }, active: 'Home'
    } unless user_session.include?(:tabs)
  end

  def another_level_breadcrumb
    same_level_for_all = 1 # ultimo nivel, por enquanto o breadcrumb só comporta 3 níveis
    user_session[:tabs][:opened][user_session[:tabs][:active]][:breadcrumb][same_level_for_all] = { name: params[:bread], url: params } if params[:bread].present?
  end

  def current_menu_context
    return unless user_signed_in?

    # contexto indicado eh diferente do contexto da aba ativa
    contexts = params['contexts'].split(',').map(&:to_i) rescue []
    set_active_tab_to_home if ((!contexts.empty? && !contexts.include?(active_tab[:url][:context])) || controller_path == 'devise/users')
  end

  def set_active_tab(tab_id)
    user_session[:tabs][:active] = tab_id
  end

  def set_active_tab_to_home
    clear_breadcrumb_home
    set_active_tab('Home')
  end

  def active_tab
    user_session[:tabs][:opened][user_session[:tabs][:active]] if user_signed_in?
  end

  def clear_breadcrumb_home
    user_session[:tabs][:opened]['Home'][:breadcrumb] = [user_session[:tabs][:opened]['Home'][:breadcrumb].first]
  end

  def prepare_for_pagination
    @current_page = user_session[:current_page]
    user_session[:current_page] = nil

    @current_page = params[:current_page] if @current_page.nil?
    @current_page = '1' if @current_page.nil?
  end

  def hold_pagination
    user_session[:current_page] = @current_page
  end

  def prepare_for_group_selection
    @can_select_group = true
  end

  def get_group_allocation_tag
     return unless active_tab[:url][:context] == Context_Curriculum_Unit.to_i

    # verifica se o grupo foi passado e se é um grupo válido
    unless params[:selected_group].present? and !!(allocation_tag_id_group = AllocationTag.find_by_group_id(params[:selected_group]).try(:id))
      allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
      allocation_tag_id_group = (params[:selected_group] = allocation_tag.group_id).nil? ? RelatedTaggable.where('group_id IN (?)', current_user.groups(nil, Allocation_Activated, nil, nil, active_tab[:url][:id]).pluck(:id)).first.group_at_id : allocation_tag.id
    end

    user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:allocation_tag_id] = allocation_tag_id_group
    log_access(allocation_tag_id_group) # save access
  end

  def select_group
    prepare_for_group_selection
    get_group_allocation_tag

    redirect_to URI(request.referer).path, selected_group: params[:selected_group]
  end

  def after_sign_in_path_for(resource_or_scope)
    LogAccess.login(user_id: current_user.id, ip: request.remote_ip) rescue nil
    super
  end

  def get_groups_by_tool(tool)
    @groups = tool.groups
  end

  def get_groups_by_allocation_tags(ats = nil)
    @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: (ats || params[:allocation_tags_ids].split(" ").flatten)})
  end

  def set_locale
    if user_signed_in?
      personal_options = PersonalConfiguration.find_or_create_by_user_id(current_user.id, default_locale: (params[:locale] || I18n.default_locale))
      personal_options.update_attributes(default_locale: params[:locale]) if (params[:locale].present? and params[:locale].to_s != personal_options.default_locale.to_s)
      params[:locale] = personal_options.default_locale
    end

    I18n.locale = ['pt_BR', 'en_US'].include?(params[:locale]) ? params[:locale] : I18n.default_locale
    params.delete(:locale) if user_signed_in?
  end

  ## Parametros de locale para paginas externas
  def default_url_options(options={})
    params.include?('locale') ? {locale: params[:locale]} : {}
  end

  def set_current_user
    User.current = current_user
  end

  private

    def opened_or_new_tab?(tab_id)
      (user_session[:tabs][:opened].has_key?(tab_id)) or (user_session[:tabs][:opened].length < Max_Tabs_Open.to_i)
    end

    def set_session_opened_tabs(hash_url, params_url)
      user_session[:tabs][:opened][params[:id]] = { breadcrumb: [{name: params[:name], tab: params[:tab] || params[:name], url: params_url}], url: hash_url }
      set_active_tab params[:id]
    end

    def init_xmpp_im
      conf = YAML::load_file(File.join('config','im.yml'))
      @_dominio = conf['dominio']
      @_ip = conf['ip']
      @_porta = conf['porta']
    end

    def crud_action
      case params[:action]
      when 'new', 'create'
        :create
      when 'edit', 'update'
        :update
      end
    end

    def log_access(allocation_tag_id)
      LogAccess.group(user_id: current_user.id, allocation_tag_id: allocation_tag_id, ip: request.remote_ip) rescue nil if (user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:context].to_i == Context_Curriculum_Unit)
    end

end
