class AssignmentCommentsController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_filter :get_ac, only: :new
  before_filter :set_current_user, only: [:create, :update, :destroy]
  before_filter only: [:edit, :update, :destroy] do |controller|
    @assignment_comment = AssignmentComment.find(params[:id])
  end

  layout false

  def index
    @assignment = SentAssignment.find(params[:sent_assignment_id]).assignment
    render partial: "list", locals: {comments: sent_assignment.assignment_comments}
  end

  def new
    @sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: @ac.id).first_or_create
    @assignment_comment = AssignmentComment.new sent_assignment_id: @sent_assignment.id
    @assignment_comment.files.build
  end

  def create
    authorize! :create, AssignmentComment, on: [active_tab[:url][:allocation_tag_id]]

    @assignment_comment = AssignmentComment.new assignment_comment_params
    @assignment_comment.user = current_user

    if @assignment_comment.save
      render partial: "comment", locals: {comment: @assignment_comment}
    else
      render_error_json
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def edit
    @assignment_comment.files.build if @assignment_comment.files.empty?
  end

  def update
    if @assignment_comment.update_attributes(assignment_comment_params)
      render json: {success: true, notice: t('assignment_comments.success.edit')}
    else
      render_error_json
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def show
    render partial: "comment", locals: {comment: AssignmentComment.find(params[:id])}
  end

  def destroy
    @assignment_comment.destroy

    render json: {success: true, notice: t("assignment_comments.success.removed")}
  rescue => error
    request.format = :json
    raise error.class
  end

  def download
    is_observer_or_responsible, file = AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id), CommentFile.find(params[:file_id])
    raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, {sent_assignment: file.assignment_comment.sent_assignment}) or is_observer_or_responsible

    download_file(:back, file.attachment.path, file.attachment_file_name)
  end

  private

    def assignment_comment_params
      params.require(:assignment_comment).permit(:sent_assignment_id, :comment, files_attributes: [:id, :attachment, :_destroy])
    end

    def render_error_json
      render json: {success: false, alert: t('assignment_comments.error.general_message')}, status: :unprocessable_entity
    end

end
