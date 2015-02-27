class PostsController < ApplicationController
  require "em-websocket"

  include SysLog::Actions

  # before_filter :authenticate_user!
  before_filter :prepare_for_pagination

  load_and_authorize_resource except: [:index, :user_posts, :create, :show]

  ## GET /discussions/1/posts
  ## GET /discussions/1/posts/20120217/[news, history]/order/asc/limit/10
  require 'will_paginate/array'
  def index
    @discussion, @user = Discussion.find(params[:discussion_id]), current_user

    @academic_allocation_id = AcademicAllocation.where(academic_tool_id: @discussion.id, academic_tool_type: "Discussion", 
      allocation_tag_id: [active_tab[:url][:allocation_tag_id], AllocationTag.find_by_offer_id(active_tab[:url][:id]).id]).first.try(:id)
    authorize! :index, Discussion, {on: [@allocation_tags = active_tab[:url][:allocation_tag_id] || @discussion.allocation_tags.pluck(:id)], read: true}

    @researcher = current_user.is_researcher?(AllocationTag.find(@allocation_tags).related)
    @class_participants = AllocationTag.get_participants(active_tab[:url][:allocation_tag_id], {all: true}).map(&:id)

    @posts = []
    @can_interact, @can_post = @discussion.user_can_interact?(current_user.id), (can? :create, Post, on: [@allocation_tags])

    p = params.slice(:date, :type, :order, :limit, :display_mode, :page)

    @display_mode = p['display_mode'] ||= 'tree'

    if (p['display_mode'] == "list" or params[:format] == "json")
      # se for em forma de lista ou para o mobilis, pesquisa pelo método posts
      p['page'] ||= @current_page
      p['type'] ||= "history"
      p['date'] = DateTime.parse(p['date']) if params[:format] == "json" and p.include?('date')
      @posts    = @discussion.posts(p, @allocation_tags)
    else
      @posts = @discussion.posts_by_allocation_tags_ids(@allocation_tags) # caso contrário, recupera e reordena os posts do nível 1 a partir das datas de seus descendentes
    end

    respond_to do |format|
      format.html
      format.json  {
        period = (@posts.empty?) ? ["#{p['date']}", "#{p['date']}"] : ["#{@posts.first.updated_at}", "#{@posts.last.updated_at}"].sort

        if params[:mobilis].present?
          render json: { before: @discussion.count_posts_before_period(period, @allocation_tags), after: @discussion.count_posts_after_period(period, @allocation_tags), posts: @posts.map(&:to_mobilis)}
        else
          render json: @discussion.count_posts_after_and_before_period(period, @allocation_tags) + @posts.map(&:to_mobilis)
        end
      }
    end
  end

  ## GET /discussions/1/posts/user/1
  ## all posts of the user
  def user_posts
    @user = User.find(params[:user_id])
    @discussion = Discussion.find(params[:discussion_id])

    allocation_tags = AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
    @posts = Post.joins(:academic_allocation).where(academic_allocations: {allocation_tag_id: allocation_tags, academic_tool_id: @discussion.id, academic_tool_type: "Discussion"}, user_id: @user.id)

    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @posts }
    end
  end

  ## POST /discussions/:id/posts
  def create
    authorize! :create, Post

    if new_post_under_discussion(Discussion.find(params[:discussion_id]))
      render json: {result: 1, post_id: @post.id, parent_id: @post.parent_id}, status: :created
    else
      render json: {result: 0}, status: :unprocessable_entity
    end
  end

  ## PUT /discussions/:id/posts/1
  def update
    if @post.update_attributes(content: params[:discussion_post][:content])
      render json: {success: true, post_id: @post.id, parent_id: @post.parent_id}
    else
      render json: @post.errors.full_messages, status: :unprocessable_entity
    end
  end

  ## GET /discussions/:id/posts/1
  def show
    post = Post.find(params[:id])
    post = Post.find(post.grandparent(level = 1).first["grandparent_id"].to_i) if params[:grandparent] == "true"

    allocation_tag_id = active_tab[:url][:allocation_tag_id]
    can_interact = post.discussion.user_can_interact?(current_user.id)
    can_post = can?(:create, Post, on: [allocation_tag_id])

    @researcher = (params[:researcher] == "true" or params[:researcher] == true)
    @class_participants = AllocationTag.get_participants(allocation_tag_id, {all: true}).pluck(:id)

    render partial: "post", locals: {post: post, display_mode: nil, can_interact: can_interact, can_post: can_post, current_user: current_user, new_post: (params[:new_post] ? params[:id] : nil) }
  end

  ## DELETE /posts/1
  def destroy
    @post.destroy

    render json: {result: :ok}
  end

  private

    def post_params
      params.require(:discussion_post).permit(:content, :parent_id, :discussion_id)
    end

    def new_post_under_discussion(discussion)
      allocation_tag_ids  = AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
      academic_allocation = discussion.academic_allocations.where(allocation_tag_id: allocation_tag_ids).first

      @post = Post.new(post_params)
      @post.user_id = current_user.id
      @post.academic_allocation_id = academic_allocation.id
      @post.profile_id = current_user.profiles_with_access_on(:create, :posts, allocation_tag_ids, true).first

      @post.save
    end

end
