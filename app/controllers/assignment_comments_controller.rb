class AssignmentCommentsController < ApplicationController

  before_filter :set_current_user, only: [:create, :update, :destroy]

  include SysLog::Actions
  include FilesHelper

  layout false

  def index
    @assignment = SentAssignment.find(params[:sent_assignment_id]).assignment
    render partial: "list", locals: {comments: sent_assignment.assignment_comments}
  end

  def new
    ac = AcademicAllocation.where(academic_tool_id: params[:assignment_id], academic_tool_type: "Assignment", allocation_tag_id: active_tab[:url][:allocation_tag_id]).first.id
    @sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: ac).first_or_create
    @assignment_comment = AssignmentComment.new sent_assignment_id: @sent_assignment.id, user_id: current_user.id
    @assignment_comment.files.build
  end

  def create
    authorize! :create, AssignmentComment, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    params[:assignment_comment][:user_id] = current_user.id

    @assignment_comment = AssignmentComment.create! params[:assignment_comment]
    render partial: "comment", locals: {comment: @assignment_comment}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    error_message = I18n.translate!("assignment_comments.error.#{error}", raise: true) rescue t("assignment_comments.error.general_message")
    render json: {success: false, alert: error.message || error_message}, status: :unprocessable_entity
  end

  def edit
    @assignment_comment = AssignmentComment.find(params[:id])
    @assignment_comment.files.build if @assignment_comment.files.empty?
  end

  def update
    @assignment_comment = AssignmentComment.find(params[:id])
    @assignment_comment.update_attributes!(params[:assignment_comment])
    render json: {success: true, notice: t("assignment_comments.success.edit")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    error_message = I18n.translate!("assignment_comments.error.#{error}", raise: true) rescue t("assignment_comments.error.general_message")
    render json: {success: false, alert: error.message || error_message}, status: :unprocessable_entity
  end

  def show
    render partial: "comment", locals: {comment: AssignmentComment.find(params[:id])}
  end

  def destroy
    assignment_comment = AssignmentComment.find(params[:id])
    assignment_comment.destroy
    render json: {success: true, notice: t("assignment_comments.success.remove")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    error_message = I18n.translate!("assignment_comments.error.#{error}", raise: true) rescue t("assignment_comments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity
  end

  def download
    is_observer_or_responsible, file = AllocationTag.find(allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id), CommentFile.find(params[:file_id])
    sent_assignment = file.assignment_comment.sent_assignment
    raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, {sent_assignment: sent_assignment}) or is_observer_or_responsible
    download_file(:back, file.attachment.path, file.attachment_file_name)
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t("assignment_files.error.download")}, status: :unprocessable_entity
  end
  
end
