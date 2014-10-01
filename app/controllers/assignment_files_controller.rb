class AssignmentFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_filter :set_current_user, only: [:destroy]
  before_filter :get_ac, only: [:new]
  layout false

  def new
    sent_assignment  = SentAssignment.where(user_id: current_user.id, group_assignment_id: GroupAssignment.by_user_id(current_user.id, @ac.id), academic_allocation_id: @ac.id).first_or_create
    @assignment_file = AssignmentFile.new sent_assignment_id: sent_assignment.id
  end

  def create
    authorize! :create, AssignmentFile, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    raise CanCan::AccessDenied unless @own_assignment = Assignment.owned_by_user?(current_user.id, {sent_assignment: SentAssignment.find(params[:assignment_file][:sent_assignment_id])})
    @assignment_file = AssignmentFile.create! params[:assignment_file].merge({user_id: current_user.id})

    render partial: "file", locals: {file: @assignment_file}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render_json_error(error, "assignment_files.error", "new")
  end

  def download
    is_observer_or_responsible = AllocationTag.find(allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)

    if params[:zip].present?
      sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: @ac.id).first_or_create
      raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, {sent_assignment: sent_assignment}) or is_observer_or_responsible
      zip_name = [Assignment.find(params[:assignment_id]).name, (params[:group_id].nil? ? User.find(params[:student_id]).nick : GroupAssignment.find(params[:group_id]).group_name)].join(' - ') # activity I - Student I
      path_zip = compress({ files: sent_assignment.assignment_files, table_column_name: 'attachment_file_name', name_zip_file: zip_name })
      download_file(:back, path_zip)
    else
      file = AssignmentFile.find(params[:id])
      raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, {sent_assignment: file.sent_assignment}) or is_observer_or_responsible
      download_file(:back, file.attachment.path, file.attachment_file_name)
    end

  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render js: "flash_message('#{t(:file_error_nonexistent_file)}', 'alert');"
  end

  def destroy
    AssignmentFile.find(params[:id]).destroy
    render json: {success: true, notice: t("assignment_files.success.removed")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render_json_error(error, "assignment_files.error", "remove")
  end

end
