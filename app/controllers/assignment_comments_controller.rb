class AssignmentCommentsController < ApplicationController

  include SysLog::Actions
  include FilesHelper

  layout false

  def index
    sent_assignment = SentAssignment.find(params[:sent_assignment_id])
    @assignment = sent_assignment.assignment
    comments    = sent_assignment.assignment_comments
    render partial: "list", locals: {comments: comments}
  end

  def new
    @user, ac = current_user, AcademicAllocation.where(academic_tool_id: params[:assignment_id], academic_tool_type: "Assignment", allocation_tag_id: active_tab[:url][:allocation_tag_id]).first.id
    @sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: ac).first_or_create
    @assignment_comment = AssignmentComment.new sent_assignment_id: @sent_assignment.id, user_id: @user.id
    @assignment_comment.files.build
  end

  def create
    authorize! :create, AssignmentComment, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    params[:assignment_comment][:user_id] = current_user.id

    @assignment_comment = AssignmentComment.new params[:assignment_comment]
    raise "date_range" unless @assignment_comment.assignment.in_time?(allocation_tag_id, current_user.id)
    @assignment_comment.save!
    render partial: "comment", locals: {comment: @assignment_comment}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    error_message = I18n.translate!("assignment_comments.error.#{error.message}", raise: true) rescue t("assignment_comments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity
  end

  def edit
    @assignment_comment = AssignmentComment.find(params[:id])
    @assignment_comment.files.build if @assignment_comment.files.empty?
  end

  def update
    @assignment_comment = AssignmentComment.find(params[:id])
    raise CanCan::AccessDenied unless @assignment_comment.user_id == current_user.id
    raise "date_range" unless @assignment_comment.assignment.in_time?(active_tab[:url][:allocation_tag_id], current_user.id)
    @assignment_comment.update_attributes!(params[:assignment_comment])

    render json: {success: true, notice: t("assignment_comments.success.edit")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    error_message = I18n.translate!("assignment_comments.error.#{error.message}", raise: true) rescue t("assignment_comments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity
  end

  def show
    render partial: "comment", locals: {comment: AssignmentComment.find(params[:id])}
  end

  def destroy
    assignment_comment = AssignmentComment.find(params[:id])
    raise CanCan::AccessDenied unless assignment_comment.user_id == current_user.id
    raise "date_range" unless assignment_comment.assignment.in_time?(active_tab[:url][:allocation_tag_id], current_user.id)

    if assignment_comment.destroy
      render json: {success: true, notice: t("assignment_comments.success.remove")}
    else
      render json: {success: false, alert: t("assignment_comments.error.general_message")}, status: :unprocessable_entity
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    error_message = I18n.translate!("assignment_comments.error.#{error.message}", raise: true) rescue t("assignment_comments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity
  end

  def download
    is_observer_or_responsible = AllocationTag.find(allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
    file = CommentFile.find(params[:file_id])
    sent_assignment = file.assignment_comment.sent_assignment
    raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, {sent_assignment: sent_assignment}) or is_observer_or_responsible
    download_file(:back, file.attachment.path, file.attachment_file_name)
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t("assignment_files.error.download")}, status: :unprocessable_entity
  end
  
end
