class PostsController < ApplicationController

  include SysLog::Actions

  before_filter :authenticate_user!
  before_filter :prepare_for_pagination

  load_and_authorize_resource except: [:index, :show, :create]

  ## GET /discussions/1/posts
  ## GET /discussions/1/posts/20120217/[news, history]/order/asc/limit/10
  def index
    @discussion = Discussion.find(params[:discussion_id])

    # group allocation tag
    allocation_tags = active_tab[:url][:allocation_tag_id] || @discussion.allocation_tags.map(&:id) # procurar problema no mobilis, ele nao envia a allocation tag da turma
    authorize! :index, Discussion, {on: [allocation_tags], read: true}

    @posts = []
    @can_interact = @discussion.user_can_interact?(current_user.id)
    p      = params.select { |k, v| ['date', 'type', 'order', 'limit', 'display_mode', 'page'].include?(k) }

    @display_mode = p['display_mode'] ||= 'tree'

    if (p['display_mode'] == "list" or params[:format] == "json")
      # se for em forma de lista ou para o mobilis, pesquisa pelo método posts
      p['page'] ||= @current_page
      p['type'] ||= "history"
      p['date'] = Time.parse(p['date']) if params[:format] == "json" and p.include?('date')
      @posts    = @discussion.posts(p, allocation_tags)
    else
      # caso contrário, recupera e reordena os posts do nível 1 a partir das datas de seus descendentes
      @latest_posts = @discussion.latest_posts(allocation_tags)
      @posts        = Post.reorder_by_latest_posts(@latest_posts, @discussion.posts_by_allocation_tags_ids(allocation_tags).where(parent_id: nil))
    end

    respond_to do |format|
      format.html
      format.json  {
        period = (@posts.empty?) ? ["#{p['date']}", "#{p['date']}"] : ["#{@posts.first.updated_at}", "#{@posts.last.updated_at}"].sort
        if params[:mobilis].present?
          render json: { before: @discussion.count_posts_before_period(period, allocation_tags), after: @discussion.count_posts_after_period(period, allocation_tags), posts: @posts.map(&:to_mobilis)} 
        else          
          render json: @discussion.count_posts_after_and_before_period(period, allocation_tags) + @posts.map(&:to_mobilis)
        end
      }
    end
  end

  ## GET /discussions/1/posts/user/1
  ## all posts of the user
  def show
    @posts = Discussion.find(params[:discussion_id]).discussion_posts.where(:user_id => params[:user_id])

    respond_to do |format|
      format.html { render :layout => false }
      format.json { render :json => @posts }
    end
  end

  ## POST /discussions/:id/posts
  def create
    authorize! :create, Post

    discussion_id       = params[:discussion_post].include?(:discussion_id) ? params[:discussion_post][:discussion_id] : params[:discussion_id]
    allocation_tag_ids  = AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
    academic_allocation = AcademicAllocation.where(academic_tool_type: "Discussion", academic_tool_id: discussion_id, allocation_tag_id: allocation_tag_ids).first
    params[:discussion_post][:academic_allocation_id] = academic_allocation.id

    @post = Post.new(params[:discussion_post])

    @post.user_id    = current_user.id
    @post.profile_id = current_user.profiles_with_access_on(:create, :posts, @post.discussion.academic_allocations.map(&:allocation_tag).map(&:related), true).first
    @post.level      = @post.parent.level.to_i + 1 unless @post.parent_id.nil?

    respond_to do |format|
      if @post.save
        format.html { redirect_to(discussion_posts_path(discussion_id), notice: t(:created, :scope => [:posts, :create])) }
        format.xml  { render xml: @post, status: :created }
        format.json { render json: {result: 1, post_id: @post.id}, status: :created }
      else
        format.html { redirect_to(discussion_posts_path(@post.discussion), alert: t(:not_created, scope: [:posts, :create])) }
        format.xml  { render xml: @post.errors, status: :unprocessable_entity }
        format.json { render json: {result: 0}, status: :unprocessable_entity }
      end
    end
  end

  ## PUT /discussions/:id/posts/1
  def update
    respond_to do |format|
      if @post.update_attributes(params[:discussion_post])
        format.html { redirect_to(discussion_posts_path(@post.discussion), :notice => t(:updated, :scope => [:posts, :update])) }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { redirect_to(discussion_posts_path(@post.discussion), :alert => t(:not_updated, :scope => [:posts, :update])) }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
        format.json { render :json => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  ## DELETE /posts/1
  def destroy
    @post.files.each do |file|
      file.delete
      File.delete(file.attachment.path) if File.exist?(file.attachment.path)
    end

    @post.destroy

    respond_to do |format|
      format.html { render :json => {:result => :ok} }
      format.xml  { head :ok }
      format.json { render :json => {:result => :ok} }
    end
  end

end
