class ScheduleEventFilesController < ApplicationController

  # include SysLog::Actions
  include ScheduleEventFilesHelper

  before_action :set_current_user, only: [:destroy, :create]
  before_action :get_ac, only: :new

  layout false

  def new
    # @schedule_event = ScheduleEvent.find(params['tool_id'])
    # verify_ip!(@schedule_event.id, :schedule_event, @schedule_event.controlled, :text)
    # group = GroupAssignment.by_user_id(current_user.id, @ac.id)
    academic_allocation_user = AcademicAllocationUser.find_or_create_one(@ac.id, active_tab[:url][:allocation_tag_id], params[:student_id])
    @schedule_event_file = ScheduleEventFile.new academic_allocation_user_id: academic_allocation_user.id
  end

  def create
    # authorize! :create, ScheduleEventFile, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    # verify_owner!(schedule_event_file_params)
    create_many
    # set_ip_user

    render partial: 'files', locals: { files: @schedule_event_files, disabled: false }
  # rescue ActiveRecord::AssociationTypeMismatch
  #   render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  # rescue CanCan::AccessDenied
  #   render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  # rescue => error
  #   render_json_error(error, 'schedule_event_files.error', (error == 'not_started_up' ? 'not_started_up' : 'new'))
  end

  def destroy
    @schedule_event_file = ScheduleEventFile.find(params[:id])
    # set_ip_user
    @schedule_event_file.destroy

    render json: { success: true, notice: t('assignment_files.success.removed') }
  # rescue CanCan::AccessDenied
  #   render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  # rescue => error
  #   render_json_error(error, 'assignment_files.error', 'remove')
  end

  # def download
  #   if Exam.verify_blocking_content(current_user.id)
  #     redirect_to list_assignments_path, alert: t('assignments.restrict_assignment')
  #   else
  #     allocation_tag_id = active_tab[:url][:allocation_tag_id]
  #
  #     if params[:zip].present?
  #       assignment = ScheduleEvent.find(params[:assignment_id])
  #       academic_allocation_user = assignment.academic_allocation_users.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocations: {allocation_tag_id: allocation_tag_id}).first
  #       path_zip   = compress_file({ files: academic_allocation_user.assignment_files, table_column_name: 'attachment_file_name', name_zip_file: assignment.name })
  #     else
  #       file = ScheduleEventFile.find(params[:id])
  #       academic_allocation_user = file.academic_allocation_user
  #       path_zip  = file.attachment.path
  #       file_name = file.attachment_file_name
  #     end
  #     raise CanCan::AccessDenied unless ScheduleEventFile.owned_by_user?(current_user.id, { academic_allocation_user: academic_allocation_user }) || AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(current_user.id)
  #     download_file(:back, path_zip, file_name)
  #   end
  # end

  private

    def schedule_event_file_params
      params.require(:schedule_event_file).permit(:user_id, :academic_allocation_user_id, :attachment)
    end

    def create_one(params = schedule_event_file_params)
      @schedule_event_file = ScheduleEventFile.new(params)
      @schedule_event_file.user = current_user

      ScheduleEventFile.transaction do
        @schedule_event_file.allocation_tag_ids_associations = @allocation_tags_ids
        @schedule_event_file.save!
      end

      @schedule_event_file
    rescue => error
      raise error
    end

    def create_many
      ScheduleEventFile.transaction do
        unless params[:files].blank?
          @schedule_event_files = []
          params[:files].each do |file|
            create_one(schedule_event_file_params.merge!(attachment: file))
            @schedule_event_files << @schedule_event_file
          end
          @schedule_event_file = nil
        end
      end
    rescue => error
      raise error
    end
end
