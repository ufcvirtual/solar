class PostsController < ApplicationController
  require "em-websocket"

  include SysLog::Actions

  # before_filter :authenticate_user!
  before_filter :prepare_for_pagination
  before_filter :set_current_user, only: [:destroy, :create, :update, :publish, :post_files]

  load_and_authorize_resource except: [:index, :user_posts, :create, :show, :evaluate, :publish, :post_files]

  ## GET /discussions/1/posts
  ## GET /discussions/1/posts/20120217/[news, history]/order/asc/limit/10
  require 'will_paginate/array'
  def index
    if Exam.verify_blocking_content(current_user.id)
      redirect_to :back, alert: t('exams.restrict')
    else
      @discussion, @user = Discussion.find(params[:discussion_id]), current_user

      @academic_allocation = AcademicAllocation.where(academic_tool_id: @discussion.id, academic_tool_type: 'Discussion', allocation_tag_id: [active_tab[:url][:allocation_tag_id], AllocationTag.find_by_offer_id(active_tab[:url][:id]).id]).first
      authorize! :index, Discussion, { on: [@allocation_tags = active_tab[:url][:allocation_tag_id] || @discussion.allocation_tags.pluck(:id)], read: true }

      @researcher = current_user.is_researcher?(AllocationTag.where(id: @allocation_tags).map(&:related).flatten.uniq)
      @class_participants = AllocationTag.get_participants(active_tab[:url][:allocation_tag_id], { all: true }).map(&:id)

      @posts = []
      @can_interact = @discussion.user_can_interact?(current_user.id)
      @can_post = (can? :create, Post, on: [@allocation_tags])
      @can_evaluate = can? :evaluate, Discussion, {on: [@allocation_tags]}
      @can_comment = can? :create, Comment, {on: [@allocation_tags]}

      p = params.slice(:date, :type, :order, :limit, :display_mode, :page)

      @display_mode = p['display_mode'] ||= 'tree'
      @post = Post.new
      @post.files.build

      @files = @discussion.enunciation_files

      if (p['display_mode'] == "list" || params[:format] == "json")
        # se for em forma de lista ou para o mobilis, pesquisa pelo método posts
        p['page'] ||= @current_page
        p['type'] ||= "history"
        p['date'] = DateTime.parse(p['date']) if params[:format] == "json" && p.include?('date')
        @posts    = @discussion.posts_not_limit(p, @allocation_tags, current_user.id).paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
      elsif (@display_mode == 'user' )
        my_list = true
        @posts = @discussion.posts_by_allocation_tags_ids(@allocation_tags, current_user.id, my_list).paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page) # caso contrário, recupera e reordena os posts do nível 1 a partir das datas de seus descendentes
      else
        @posts = @discussion.posts_by_allocation_tags_ids(@allocation_tags, current_user.id).paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page) # caso contrário, recupera e reordena os posts do nível 1 a partir das datas de seus descendentes
      end

      if current_user.is_student?([@allocation_tags].flatten)
        @acu = AcademicAllocationUser.find_or_create_one(@academic_allocation.id, [@allocation_tags].flatten, current_user.id, nil)
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
  end

  def new
    @post = Post.new
    @post.files.build
  end

  ## GET /discussions/1/posts/user/1
  ## all posts of the user
  def user_posts
    if Exam.verify_blocking_content(current_user.id)
      render text: t('exams.restrict')
    else
      @user = User.find(params[:user_id])
      @discussion = Discussion.find(params[:discussion_id])
      @score_type = params[:score_type]

      @allocation_tags = AllocationTag.find(@allocation_tag_id = active_tab[:url][:allocation_tag_id]).related
      raise CanCan::AccessDenied if params[:user_id].to_i != current_user.id && !AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)

      @posts = Post.joins(:academic_allocation).where(academic_allocations: { allocation_tag_id: @allocation_tags, academic_tool_id: @discussion.id, academic_tool_type: 'Discussion' }, user_id: @user.id, draft: false).order('updated_at DESC')

      @academic_allocation = @discussion.academic_allocations.where(allocation_tag_id: @allocation_tags).first
      @can_evaluate = can? :evaluate, Discussion, { on: @allocation_tag_id }
      @alluser = AcademicAllocationUser.find_one(@academic_allocation.id, @user.id, nil, false, @can_evaluate)# unless @posts.blank?
      @is_student = @user.is_student?([@allocation_tags].flatten)

      respond_to do |format|
        format.html { render layout: false }
        format.json { render json: @posts }
      end
    end
  end

  ## POST /discussions/:id/posts
  def create
    authorize! :create, Post

    if new_post_under_discussion(Discussion.find(params[:discussion_id]))
      render json: {result: 1, post_id: @post.id, parent_id: @post.parent_id}, status: :created
    else
      render json: { result: 0, alert: @post.errors.full_messages.join('; ') }, status: :unprocessable_entity
    end
  rescue => error
    if @post
      render json: { result: 0, alert: @post.errors.full_messages.join('; ') }, status: :unprocessable_entity
    else
      render_json_error(error, 'discussions.error')
    end
  end

  ## PUT /discussions/:id/posts/1
  def update
    @post = Post.find(params[:id])
    if @post.update_attributes post_params
      render json: {success: true, post_id: @post.id, parent_id: @post.parent_id}
    else
      render json: { result: 0, alert: @post.errors.full_messages.join('; ') }, status: :unprocessable_entity
    end
  rescue => error
    if @post
      render json: { result: 0, alert: @post.errors.full_messages.join('; ') }, status: :unprocessable_entity
    else
      render_json_error(error, 'discussions.error')
    end
  end

  def publish
    @post = Post.find(params[:id])
    @post.update_attributes draft: false
    render json: { success: true, post_id: @post.id, discussion_id: @post.discussion.id, content: @post.content, ac_id: @post.academic_allocation_id, parent_id: @post.parent_id }, status: :ok
  rescue => error
    render_json_error(error, 'discussions.error')
  end

  ## GET /discussions/:id/posts/1
  def show
    post = Post.find(params[:id])
    post = post.grandparent(level = 1) if params[:grandparent] == "true"

    allocation_tag_id = active_tab[:url][:allocation_tag_id]
    can_interact = post.discussion.user_can_interact?(current_user.id)
    can_post = can?(:create, Post, on: [allocation_tag_id])
    @can_evaluate = (can? :evaluate, Discussion, {on: [@allocation_tags]})

    @researcher = (params[:researcher] == "true" or params[:researcher] == true)
    @class_participants = AllocationTag.get_participants(allocation_tag_id, { all: true }).map(&:id)

    render partial: 'post', locals: { post: post, display_mode: nil, can_interact: can_interact, can_post: can_post, current_user: current_user, new_post: (params[:new_post] ? params[:id] : nil) }
  end

  ## DELETE /posts/1
  def destroy
    if @post.destroy
      render json: { result: :ok }
    else
      render json: { alert: @post.errors.full_messages.join('; ') }, status: :unprocessable_entity
    end
  rescue => error
    render json: { alert: @post.errors.full_messages.join('; ') }, status: :unprocessable_entity
  end

  # render files to update a post
  def post_files
    post = Post.find(params[:id])
    post.can_change?
    respond_to do |format|
      format.json { render json: post.files }
    end
  rescue
    render json: { alert: post.errors.full_messages.join('; ') }, status: :unprocessable_entity
  end

  private

    def post_params
      params.require(:post).permit(:content, :parent_id, :discussion_id, :draft, files_attributes: [:id, :attachment, :_destroy])
    end

    def new_post_under_discussion(discussion)
      allocation_tag_ids  = AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
      academic_allocation = discussion.academic_allocations.where(allocation_tag_id: allocation_tag_ids).first

      aau = AcademicAllocationUser.find_or_create_one(academic_allocation.id, active_tab[:url][:allocation_tag_id], current_user.id, nil, true, nil)

      @post = Post.new(post_params)
      @post.user_id = current_user.id
      @post.academic_allocation_id = academic_allocation.id
      @post.academic_allocation_user_id = aau.try(:id)
      @post.profile_id = current_user.profiles_with_access_on(:create, :posts, allocation_tag_ids, true).first
      @post.save
    end

end
