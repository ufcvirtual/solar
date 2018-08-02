class ScheduleEventFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include ScheduleEventFilesHelper

  before_action :set_current_user, only: [:destroy, :create]
  before_action :get_ac, only: :new

  layout false

  def new
    if ['not_started', 'to_send'].include?(params[:situation])
      render json: { alert: t('schedule_event_files.error.situation') }, status: :unprocessable_entity
    else
      academic_allocation_user = AcademicAllocationUser.find_or_create_one(@ac.id, active_tab[:url][:allocation_tag_id], params[:student_id])
      @schedule_event_file = ScheduleEventFile.new academic_allocation_user_id: academic_allocation_user.id
    end
  end

  def create
    authorize! :create, ScheduleEventFile, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    create_many

    render partial: 'files', locals: { files: @schedule_event_files, disabled: false }
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid
    render json: { success: false, alert: t('schedule_event_files.error.wrong_type') }, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'schedule_event_files.error', (error == 'attachment_file_size_too_big' ? 'attachment_file_size_too_big' : 'new'))
  end

  def online_correction
    # authorize! :online_correction, ScheduleEventFile, on: active_tab[:url][:allocation_tag_id]
    @canvas_data = ScheduleEventFile.find(params[:id]).file_correction.to_json
    extension = params[:extension].split('/').last
    @file_path = get_file_path(id: params[:id], file: params[:file], extension: extension)
  end

  def save_online_correction_file
    # authorize! :save_online_correction_file, ScheduleEventFile, on: active_tab[:url][:allocation_tag_id]
    @schedule_event_file = ScheduleEventFile.find(params[:id])
    @schedule_event_file.file_correction = params[:imgs]

    if @schedule_event_file.save
      render json: { success: true, notice: "Deu certo parça!!! =D" }
    else
      render json: { success: false, alert: "Deu ruim. =(" }, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule_event_file = ScheduleEventFile.find(params[:id])
    @schedule_event_file.destroy

    render json: { success: true, notice: t('schedule_event_files.success.deleted') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'schedule_event_files.error', 'remove')
  end

  def download
    if Exam.verify_blocking_content(current_user.id)
      redirect_to schedule_events_path, alert: t('schedule_events.restrict_events')
    else
      if params[:zip].present?
        event = ScheduleEvent.find(params[:event_id])
        schedule_event_files = ScheduleEventFile.get_all_event_files(params[:event_id])
        path_zip = compress_file({ files: schedule_event_files, table_column_name: 'attachment_file_name', name_zip_file: event.title })
      else
        file = ScheduleEventFile.find(params[:id])
        path_zip  = file.attachment.path
        file_name = file.attachment_file_name
      end
      download_file(:back, path_zip, file_name)
    end
  end

  private

    def schedule_event_file_params
      params.require(:schedule_event_file).permit(:user_id, :academic_allocation_user_id, :attachment, :file_correction)
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
