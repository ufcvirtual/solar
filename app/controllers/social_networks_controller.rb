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
    @oauth_redirect_url = oauth.url_for_oauth_code(:permissions => "read_stream")

    user_session[:fb_token] = oauth.get_access_token(params[:code]) if params[:code].present?
    redirect_to :pages
  end

  def fb_feed
    # Pega um objeto da ferramenta API, através da qual podemos acessar as informações do usuário no facebook
    @graph = Koala::Facebook::API.new(user_session[:fb_token]) if user_session[:fb_token].present?

    fql_query = "SELECT parent_post_id,actor_id,message,created_time,attachment,type FROM stream WHERE filter_key in (SELECT filter_key FROM stream_filter WHERE uid=me() AND type='newsfeed') AND is_hidden = 0 LIMIT 2"
    feed = @graph.fql_query(fql_query) #unless @graph.nil?

    @fb_posts = []
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
          mediaType = 'nothing'

          if feed_item['attachment']['media'].present?
            mediaType = feed_item['attachment']['media'][0]['type']
            if mediaType.eql? 'photo'
              content = feed_item['attachment']['media'][0]['src'].gsub('_s','_n')
              link = feed_item['attachment']['media'][0]['href']
            elsif mediaType.eql? 'link' or mediaType.eql? 'video' or mediaType.eql? 'swf'
              content = feed_item ['attachment']['media'][0]['src']
              link = feed_item['attachment']['media'][0]['href']
            end
          end  
          
          actor = feed_item['actor_id']
          parentPost= feed_item ['parent_post_id']
          type= feed_item['type']

          fb_post = FBPost.new(name, message, date, mediaType, actor, content, link, parentPost,type)
          @fb_posts.push(fb_post)
        end
      end
    end # if
  end

  def fb_logout
    user_session.delete(:fb_token)
    redirect_to :pages
  end
  
end
