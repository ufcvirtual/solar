class UsersController < ApplicationController

  load_and_authorize_resource :except => [:photo, :edit_photo, :fb_authentication]
  before_filter :parse_facebook_cookies # para autenticacao no facebook

  def parse_facebook_cookies
    @facebook_cookies ||= Koala::Facebook::OAuth.new(Fb_Config['app_id'], Fb_Config['secret_key']).get_user_info_from_cookie(cookies)
  end

  def mysolar
    set_active_tab_to_home

    @user           = current_user
    allocation_tags = @user.allocation_tags.where(allocations: {status: Allocation_Activated.to_i}).compact.uniq.map(&:related).flatten.uniq.sort

    ## Portlet do calendario; destacando dias que possuem eventos
    unless allocation_tags.empty?
      schedules_events       = Schedule.events(allocation_tags)
      schedules_events_dates = schedules_events.collect do |schedule_event|
        [schedule_event['start_date'].to_date.to_s(), schedule_event['end_date'].to_date.to_s()]
      end
      @scheduled_events = schedules_events_dates.flatten.uniq
    end

    #Acessa o arquivo de configuração facebook.yml
    @FB_CONFIG = Fb_Config;
    oauth = Koala::Facebook::OAuth.new(Fb_Config['app_id'], Fb_Config['secret_key'], Fb_Config['data-href'])
    # Gera a URL de autenticação
    @oauth_redirect_url= oauth.url_for_oauth_code
    #Pega um objeto da ferramenta GraphAPI, através da qual podemos acessar as informações do usuário no facebook
    @graph = Koala::Facebook::GraphAPI.new(user_session[:fb_token]) if user_session[:fb_token].present?
  end

  def fb_authentication
     oauth = Koala::Facebook::OAuth.new(Fb_Config['app_id'], Fb_Config['secret_key'], Fb_Config['data-href'])
     #Guarda o token do usuário na sessão
     user_session[:fb_token] = oauth.get_access_token(params[:code]) if params[:code].present?
     redirect_to :pages
  end

  def photo
    file_path = User.find(params[:id]).photo.path(params[:style] || :small)
    head(:bad_request) and return unless not file_path.nil? and File.exist?(file_path)
    send_file(file_path, { :disposition => 'inline', :content_type => 'image' })
  end

  def edit_photo
    render :layout => false
  end

  def update_photo
    # breadcrumb = active_tab[:breadcrumb].last
    # redirect = breadcrumb.nil? ? home_path : breadcrumb[:url]
    respond_to do |format|
      begin
        raise t(:user_error_no_file_sent) unless params.include?(:user) && params[:user].include?(:photo)
        @user.update_attributes!(params[:user])
        format.html { redirect_to :back, notice: t(:successful_update_photo) }
      rescue Exception => error
        error_msg = ''
        if error.message.index("not recognized by the 'identify'") # erro que nao teve tratamento
          error_msg = error.message
          # error_msg = [t(:photo_content_type, scope: [:activerecord, :attributes, :user]),
          #              t(:invalid_type, scope: [:activerecord, :errors, :models, :user, :attributes, :photo_content_type])].compact.join(' ')
        else # exibicao de erros conhecidos
          error_msg << error.message
        end
        format.html { redirect_to :back, alert: error_msg }
      end
    end
  end
end

