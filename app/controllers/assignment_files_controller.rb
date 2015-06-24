class AssignmentFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_filter :set_current_user, only: :destroy
  before_filter :get_ac, only: :new

  layout false

  def new
    group = GroupAssignment.by_user_id(current_user.id, @ac.id)
    sent_assignment  = SentAssignment.where(user_id: (group.nil? ? current_user.id : nil), group_assignment_id: group.try(:id), academic_allocation_id: @ac.id).first_or_create
    @assignment_file = AssignmentFile.new sent_assignment_id: sent_assignment.id
  end

  def create
    authorize! :create, AssignmentFile, on: [active_tab[:url][:allocation_tag_id]]

    sa = SentAssignment.find(assignment_file_params[:sent_assignment_id]) rescue CanCan::AccessDenied
    raise CanCan::AccessDenied unless @own_assignment = Assignment.owned_by_user?(current_user.id, { sent_assignment: sa })

    @assignment_file = AssignmentFile.new assignment_file_params
    @assignment_file.user = current_user

    if @assignment_file.save
      render partial: 'file', locals: { file: @assignment_file }
    else
      render json: { success: false, alert: @assignment_file.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end

  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'assignment_files.error', 'new', error.message)
  end

  def destroy
    @assignment_file = AssignmentFile.find(params[:id])
    @assignment_file.destroy

    render json: { success: true, notice: t('assignment_files.success.removed') }
  rescue => error
    request.format = :json
    raise error.class
  end

  def download
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    if params[:zip].present?
      assignment = Assignment.find(params[:assignment_id])
      sent_assignment = assignment.sent_assignments.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocations: {allocation_tag_id: allocation_tag_id}).first
      path_zip   = compress({ files: sent_assignment.assignment_files, table_column_name: 'attachment_file_name', name_zip_file: assignment.name })
    else
      file = AssignmentFile.find(params[:id])
      sent_assignment = file.sent_assignment
      path_zip  = file.attachment.path
      file_name = file.attachment_file_name
    end

    raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, { sent_assignment: sent_assignment }) || AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(current_user.id)
    download_file(:back, path_zip, file_name)
  end

  private

    def assignment_file_params
      params.require(:assignment_file).permit(:sent_assignment_id, :attachment)
    end

end
