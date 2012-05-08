class PostsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :prepare_for_pagination

  # load_and_authorize_resource

  # GET /discussions/1/posts
  # GET /discussions/1/posts/20120217/news/asc/order/10/limit
  # GET /discussions/1/posts/20120217/history/asc/order/10/limit
  def index
    @posts, count = [], []

    begin
      @discussion = Discussion.find(params[:discussion_id])
      @can_see = @discussion.user_can_see?(current_user.id)

      if @can_see
        @can_interact = @discussion.user_can_interact?(current_user.id)
        p = params.select { |k, v| ['date', 'type', 'order', 'limit', 'display_mode'].include?(k) }
        p['page'] = @current_page

        @display_mode = p['display_mode'] = p['display_mode'] || 'tree'
        @posts = @discussion.posts(p)

        period = (@posts.empty?) ? [p['date'], p['date']] : [@posts.first.updated_at, @posts.last.updated_at].sort
        count = @discussion.count_posts_after_and_before_period(period)
      end
    rescue
    end

    respond_to do |format|
      format.html # list.html.erb
      format.xml  { render :xml => count + @posts }
      format.json  { render :json => count + @posts }
    end
  end

  # POST /discussions/:id/posts
  # POST /discussions/:id/posts.xml
  def create
    params[:discussion_post][:user_id] = current_user.id
    at_id = Discussion.find(params[:discussion_post][:discussion_id]).allocation_tag_id
    params[:discussion_post][:profile_id] = current_user.profiles_with_access_on('create', 'posts', at_id, only_id = true).first

    @discussion_post = Post.new(params[:discussion_post])

    respond_to do |format|
      if @discussion_post.save
        format.html { redirect_to(discussion_posts_path(Discussion.find(params[:discussion_id])), :notice => 'Postagem criada com sucesso.') }
        format.xml  { render :xml => @discussion_post, :status => :created }
        format.json  { render :json => {:result => 1, :post_id => @discussion_post.id}, :status => :created }
      else
        format.html { render :json => {:result => 0} }
        format.xml  { render :xml => @discussion_post.errors, :status => :unprocessable_entity }
        format.json  { render :json => {:result => 0}, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /discussions/:id/posts/1
  # PUT /discussions/:id/posts/1.xml
  def update
    @discussion_post = Post.find(params[:id])

    respond_to do |format|
      if @discussion_post.update_attributes(params[:discussion_post])
        format.html { redirect_to(@discussion_post, :notice => 'Discussion post was successfully updated.') }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @discussion_post.errors, :status => :unprocessable_entity }
        format.json  { render :json => @discussion_post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @discussion_post = Post.find(params[:id])
    @discussion_post.destroy

    respond_to do |format|
      format.html { render :json => {:result => :ok} }
      format.xml  { head :ok }
    end
  end

  ##
  # Anexa arquivo a um post -- principalmente arquivos de audio
  ##
  def attach_file
    @file = nil
    post_id = params[:id]

    post = Post.find(post_id)
    # verifica se o forum ainda esta aberto
    discussion_closed = Discussion.find(post.discussion_id).closed?

    # verifica se o post é do usuário
    if ((not discussion_closed) and (post.user_id == current_user.id))
      attachment = {:attachment => params[:attachment]}
      @file = DiscussionPostFiles.new attachment
      @file.discussion_post_id = post_id
    end

    respond_to do |format|
      if ((not @file.nil?) and @file.save!)
        format.html { render :json => {:result => 1}, :status => :created }
      else
        format.html { render :json => {:result => 0}, :status => :unprocessable_entity }
      end
    end
  end

end
