class SocialNetworksController < ApplicationController

  layout false

  ###
  ## facebook
  ###

  FBPost = Struct.new(:name, :message, :created_time,:media_type,:actor,:adress,:link,:parent,:type)

  def fb_authenticate
    # Acessa o arquivo de configuração facebook.yml
    @FB_CONFIG = Fb_Config;
    oauth = Koala::Facebook::OAuth.new(Fb_Config['app_id'], Fb_Config['secret_key'], Fb_Config['data-href'])
    # Gera a URL de autenticação com as permissões necessárias
    @oauth_redirect_url = oauth.url_for_oauth_code()

    user_session[:fb_token] = oauth.get_access_token(params[:code]) if params[:code].present?
    redirect_to :pages
  end

  def fb_feed
    # Pega um objeto da ferramenta API, através da qual podemos acessar as informações do usuário no facebook
    @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?
    @gid = -1
    @fb_posts = []
    @fb_posts = @graph.get_object("me/home?limit=10")
  end

  def fb_feed_new
    # Pega um objeto da ferramenta API, através da qual podemos acessar as informações do usuário no facebook
    @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?
    @gid = -1
    @fb_posts = []
    @fb_posts = @graph.get_object('me/home?fields=created_time&limit=1')
    render json: {new_time: @fb_posts.first["created_time"]}
  end

  def fb_feed_group_news
    @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?
    @fb_msg_groups = []
    @fb_msg_groups = @graph.get_object(params[:id]+'/feed?fields=created_time&limit=1')
    render json: {new_time: @fb_msg_groups.first["created_time"]}
  end 

  def fb_feed_groups
    @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?
    # fql_query_messages_groups = "SELECT parent_post_id,actor_id,message,created_time,attachment,type FROM stream WHERE source_id="+ params[:id]+"LIMIT 10" 
    # messages_group = @graph.fql_query(fql_query_messages_groups)
    @gid = params[:id]
    @fb_msg_groups = []
    @fb_msg_groups = @graph.get_object(@gid+"/feed?limit=10")
    render :fb_feed     
  end  

  def fb_logout
    user_session.delete(:fb_token)
    redirect_to :pages
  end

  def fb_post_wall
      @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?
      my_post = params[:post]
      current_gid = params[:gid]
      unless my_post.empty? or @graph.nil?
        #your_api_variable.put_wall_post(article.name, {}, group_or_people_id)
        if current_gid.to_i == -1
          @graph.put_wall_post(my_post)   
          redirect_to fb_feed_social_networks_path
        else 
          @graph.put_wall_post(my_post,{},current_gid)   
          redirect_to fb_feed_group_social_networks_path(current_gid)
        end
      end    
  end
end
