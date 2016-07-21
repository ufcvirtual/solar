class AssignmentFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_filter :set_current_user, only: [:destroy, :new]
  before_filter :get_ac, only: :new

  layout false

  def new
    group = GroupAssignment.by_user_id(current_user.id, @ac.id)
    academic_allocation_user = AcademicAllocationUser.find_or_create_one(@ac.id, active_tab[:url][:allocation_tag_id], current_user.id, group.try(:id), true)
    @assignment_file = AssignmentFile.new academic_allocation_user_id: academic_allocation_user.id
  end

  def create
    verify_owner!(assignment_file_params)
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
    render_json_error(error, 'assignment_files.error', 'new')
  end

  def destroy
    @assignment_file = AssignmentFile.find(params[:id])
    @assignment_file.destroy

    render json: { success: true, notice: t('assignment_files.success.removed') }
  rescue => error
    render_json_error(error, 'assignment_files.error', 'new')
  end

  def download
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    if params[:zip].present?
      assignment = Assignment.find(params[:assignment_id])
      academic_allocation_user = assignment.academic_allocation_users.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocations: {allocation_tag_id: allocation_tag_id}).first
      path_zip   = compress({ files: academic_allocation_user.assignment_files, table_column_name: 'attachment_file_name', name_zip_file: assignment.name })
    else
      file = AssignmentFile.find(params[:id])
      academic_allocation_user = file.academic_allocation_user
      path_zip  = file.attachment.path
      file_name = file.attachment_file_name
    end
    raise CanCan::AccessDenied unless Assignment.owned_by_user?(current_user.id, { academic_allocation_user: academic_allocation_user }) || AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(current_user.id)
    download_file(:back, path_zip, file_name)
  end

  private

    def assignment_file_params
      params.require(:assignment_file).permit(:academic_allocation_user_id, :attachment)
    end

end
