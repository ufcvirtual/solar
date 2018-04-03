class CommentsController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_action :get_ac_tool, only: [:new, :index]
  before_action :set_score_type
  before_action :set_current_user, only: [:create, :update, :destroy]
  before_action only: [:edit, :update, :destroy] do |controller|
    @comment = Comment.find(params[:id])
  end

  layout false

  def new
    academic_allocation_user = AcademicAllocationUser.find_or_create_one(@ac.id, active_tab[:url][:allocation_tag_id], params[:student_id], params[:group_id], false, nil)
    raise 'no_acu' if academic_allocation_user.nil?
    @comment = Comment.new academic_allocation_user_id: academic_allocation_user.id
    @comment.files.build
  rescue => error
    render_json_error(error, 'comments.error')
  end

  def create
    authorize! :create, Comment, on: [at = active_tab[:url][:allocation_tag_id]]

    @comment      = Comment.new comment_params
    @comment.user = current_user

    if @comment.save
      return_acu_result(@comment.academic_allocation_user, at, @score_type, comment_path(@comment, score_type: @score_type))
    else
      error = @comment.files.map(&:errors).map(&:full_messages).flatten.uniq
      error = @comment.errors.full_messages if error.blank?
      render json: {succes: false, alert: error.flatten.join(', ')}, status: :unprocessable_entity
    end
  rescue => error
    render_json_error(error, 'comments.error')
  end

  def edit
    @comment.files.build if @comment.files.empty?
  end

  def update
    if @comment.update_attributes(comment_params)
      render json: { success: true, notice: t('comments.success.edit') }
    else
      error = @comment.files.map(&:errors).map(&:full_messages).flatten.uniq
      error = @comment.errors.full_messages if error.blank?
      render json: {succes: false, alert: error.flatten.join(', ')}, status: :unprocessable_entity
    end
  rescue => error
    render_json_error(error, 'comments.error')
  end

  def show
    render partial: 'comment', locals: { comment: Comment.find(params[:id]) }
  end

  def destroy
    acu = @comment.academic_allocation_user
    @comment.destroy

    return_acu_result(acu, active_tab[:url][:allocation_tag_id], @score_type)
  rescue => error
    render_json_error(error, 'comments.error')
  end

  def download
    file = CommentFile.find(params[:file_id])
    comment = file.comment

    verify_access(comment.academic_allocation_user, comment.academic_allocation.academic_tool_type)

    download_file(:back, file.attachment.path, file.attachment_file_name)
  end

  private

    def comment_params
      params.require(:comment).permit(:academic_allocation_user_id, :comment, files_attributes: [:id, :attachment, :_destroy])
    end

    def get_ac_tool
      # if tool allow creation at offer, recover all related ats
      ats = params[:tool].constantize.const_defined?("OFFER_PERMISSION") ? AllocationTag.find(active_tab[:url][:allocation_tag_id]).related : active_tab[:url][:allocation_tag_id]

      @ac = AcademicAllocation.where(academic_tool_type: params[:tool], academic_tool_id: (params[:tool_id] || params[:id]), allocation_tag_id: ats).first
    end

    def verify_access(acu, tool_type)
      is_observer_or_responsible = AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)

      if tool_type == 'Assignment'
        raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, { academic_allocation_user: acu }) || is_observer_or_responsible
      else
        raise CanCan::AccessDenied unless acu.user_id == current_user.id || is_observer_or_responsible
      end
    end

    def return_acu_result(acu, at_id, score_type, url=nil)
      ac = acu.academic_allocation
      at = ac.academic_tool_type.constantize.const_defined?("OFFER_PERMISSION") ? AllocationTag.find(at_id).related.join(',') : at_id

      score = Score.evaluative_frequency_situation(at, acu.user_id, acu.group_assignment_id, ac.academic_tool_id, ac.academic_tool_type.downcase.delete('_'), (score_type.blank? ? 'not_evaluative' : score_type)).first.situation

      render json: { success: true, situation: t("scores.index.#{score}"), class_td: score, situation_complete: t(score.to_sym), tool: ac.academic_tool_type, score_type: score_type, ac_id: ac.id, user_id: acu.user_id, group_id: acu.group_assignment_id, dont_close: true, prepend_to_list_url: url }
    rescue => error
      render json: { success: true, prepend_to_list_url: url, dont_close: true }
    end

    def set_score_type
      @score_type = (params[:comment][:score_type] rescue params[:score_type])
    end

end

