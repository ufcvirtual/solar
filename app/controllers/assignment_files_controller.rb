class AssignmentFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_filter :set_current_user, only: [:destroy]
  before_filter :get_ac, only: [:new, :download]
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
    if params[:zip].present?
      sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: @ac.id).first_or_create
      zip_name = [Assignment.find(params[:assignment_id]).name, (params[:group_id].nil? ? User.find(params[:student_id]).nick : GroupAssignment.find(params[:group_id]).group_name)].join(' - ') # activity I - Student I
      path_zip = compress({ files: sent_assignment.assignment_files, table_column_name: 'attachment_file_name', name_zip_file: zip_name })
    else
      file = AssignmentFile.find(params[:id])
    end

    raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, {sent_assignment: (sent_assignment || file.sent_assignment)}) or AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
    download_file(:back, (path_zip || file.attachment.path), (path_zip.nil? ? file.attachment_file_name : nil))

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
