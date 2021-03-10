class DiscussionsController < ApplicationController

  include SysLog::Actions
  include FilesHelper

  #doorkeeper_for :api_download
  before_action :doorkeeper_authorize!, only: [:api_download]

  layout false, except: :index

  before_action :prepare_for_group_selection, only: :index
  before_action :get_groups_by_allocation_tags, only: [:new, :create]

  before_action only: [:edit, :update, :show] do |controller|
    get_groups_by_tool(@discussion = Discussion.find(params[:id]))
  end

  def index
    begin
      @allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @user = current_user
      @discussions = Score.list_tool(@user.id, @allocation_tag_id, 'discussions', false, false, true)

    rescue
      @discussions = []
    end

    authorize! :index, Discussion, on: [@allocation_tag_id]

    @is_student = @user.is_student?([@allocation_tag_id])
    @can_evaluate = can? :evaluate, Discussion, { on: @allocation_tag_id }

    respond_to do |format|
      format.html
      format.xml  { render xml: @discussions }
      format.json  { render json: (params[:mobilis] ? {discussions: @discussions.map(&:resume) } : @discussions.map(&:resume))} # SolarMobilis: GET /groups/:group_id/discussions/mobilis_list.json
    end
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    @selected = params[:selected]

    authorize! :list, Discussion, on: @allocation_tags_ids

    @discussions = Discussion.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).distinct.select("discussions.*, schedules.start_date AS start_date").order("start_date")
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def new
    authorize! :new, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @discussion = Discussion.new
    @discussion.build_schedule(start_date: Date.current, end_date: Date.current)
    @discussion.enunciation_files.build
  end

  def create
    authorize! :create, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @discussion = Discussion.new discussion_params
    @discussion.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten

    if @discussion.save
      render_discussion_success_json('created')
    else
      @files_errors = @discussion.enunciation_files.to_a.compact.map(&:errors).map(&:full_messages).flatten.uniq.join(', ')
      @discussion.enunciation_files.build if @discussion.enunciation_files.empty?
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def edit
    authorize! :edit, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @discussion.enunciation_files.build
  end

  def update
    authorize! :update, Discussion, on: @discussion.academic_allocations.pluck(:allocation_tag_id)

    if @discussion.update_attributes(discussion_params)
      render_discussion_success_json('updated')
    else
      @files_errors = @discussion.enunciation_files.to_a.compact.map(&:errors).map(&:full_messages).flatten.uniq.join(', ')
      @discussion.enunciation_files.build if @discussion.enunciation_files.empty?
      @allocation_tags_ids = params[:allocation_tags_ids]
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @discussions = Discussion.where(id: params[:id].split(","))
    authorize! :destroy, Discussion, on: @discussions.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    if @discussions.map(&:can_remove_groups?).include?(false)
      render json: {success: false, alert: t('discussions.error.discussion_with_posts')}, status: :unprocessable_entity
    else
      evaluative = @discussions.map(&:verify_evaluatives).include?(true)
      Discussion.transaction do
        @discussions.destroy_all
      end

      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:discussions, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    end
  rescue => error
    render_json_error(error, 'discussions.error')
  end

  def show
    authorize! :show, Discussion, on: @allocation_tags_ids = params[:allocation_tags_ids]
  end

  def download
    file = DiscussionEnunciationFile.find(params[:id])
    discussion = file.discussion

    authorize! :index, Discussion, { on: discussion.allocation_tags.pluck(:id), read: true, any: true }

    download_file(:back, file.attachment.path, file.attachment_file_name)
  end

  def api_download
    api_guard_with_access_token_or_authenticate
    file = DiscussionEnunciationFile.find(params[:file_id])

    raise CanCan::AccessDenied unless (file.discussion.allocation_tags.map(&:id) & User.current.allocation_tags_ids_with_access_on(:index, 'discussions')).any?

    begin
      download_file(nil, file.attachment.path, file.attachment_file_name)
    rescue
      raise 'file not found'
    end
  rescue ActiveRecord::RecordNotFound => error
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    render json: {success: false, status: :not_found, error: error}
  rescue => error
    Rails.logger.info "[API] [ERROR] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: #{error}"
    render json: {success: false, status: :unprocessable_entity, error: error}
  end

  private

    def discussion_params
      params.require(:discussion).permit(:name, :description,
       schedule_attributes: [:id, :start_date, :end_date],
       enunciation_files_attributes: [:id, :attachment, :_destroy])
    end

    def render_discussion_success_json(method)
      render json: {success: true, notice: t(method, scope: 'discussions.success')}
    end

end
