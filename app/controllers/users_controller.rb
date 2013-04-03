require 'ostruct'

class UsersController < ApplicationController

  load_and_authorize_resource :except => [:photo, :edit_photo, :fb_authentication]
  before_filter :parse_facebook_cookies # para autenticacao no facebook
  FBPost = Struct.new(:name, :message, :created_time,:media_type,:actor,:adress,:link,:parent,:type)
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
    # Gera a URL de autenticação com as permissões necessárias
    @oauth_redirect_url= oauth.url_for_oauth_code(:permissions => "read_stream") 
    #Pega um objeto da ferramenta API, através da qual podemos acessar as informações do usuário no facebook
    @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?

    fql_query = "SELECT parent_post_id,actor_id,message,created_time,attachment,type FROM stream WHERE filter_key in (SELECT filter_key FROM stream_filter WHERE uid=me() AND type='newsfeed') AND is_hidden = 0"  
    feed = @graph.fql_query(fql_query) unless @graph.nil?

    @fb_posts  = []
      if feed.present?
        feed.each do |feed_item|
          unless feed_item['type'] == 347
            q =  "SELECT name FROM user WHERE uid =" + feed_item['actor_id'].to_s
            test_name = @graph.fql_query(q)
            if test_name.empty?
              q =  "SELECT name FROM page WHERE page_id =" + feed_item['actor_id'].to_s
              test_name = @graph.fql_query(q)
            end
            name = test_name[0]['name']
            message = feed_item['message']
            date = I18n.l(Time.at(feed_item['created_time']).to_date, :format => :default).to_s

            unless feed_item['attachment']['media'].present?
              mediaType = 'nothing'
            else
              mediaType = feed_item['attachment']['media'][0]['type']
            end
              actor = feed_item['actor_id']

            if mediaType.eql? 'photo'
              content = feed_item['attachment']['media'][0]['src'].gsub('_s','_n')
              link = feed_item['attachment']['media'][0]['href']
            elsif mediaType.eql? 'link'
              content = feed_item ['attachment']['media'][0]['src']
              link = feed_item['attachment']['media'][0]['href']
            end

              parentPost= feed_item ['parent_post_id']
              type= feed_item['type']

            fb_post = FBPost.new(name, message, date, mediaType, actor, content, link, parentPost,type)
            @fb_posts.push(fb_post)
          end
        end
      end
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

