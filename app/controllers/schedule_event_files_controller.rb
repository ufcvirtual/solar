class ScheduleEventFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include ScheduleEventFilesHelper

  before_action :set_current_user, only: [:destroy, :create]
  before_action :get_ac, only: :new

  layout false

  def new
    at_id = active_tab[:url][:allocation_tag_id]
    event = ScheduleEvent.find(params[:tool_id])
    unless event.can_receive_files?(at_id)
      render json: { alert: t('schedule_event_files.error.ended') }, status: :unprocessable_entity
    else
      academic_allocation_user = AcademicAllocationUser.find_or_create_one(@ac.id, at_id, params[:student_id], nil, true, nil)
      @schedule_event_file = ScheduleEventFile.new academic_allocation_user_id: academic_allocation_user.id
    end
  end

  def create
    authorize! :create, ScheduleEventFile, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    errors = create_many.flatten

    if errors.blank?
      render partial: 'files', locals: { files: @schedule_event_files, disabled: false, can_send_file: can?(:create, ScheduleEventFile, on: [@allocation_tag_id]), can_correct: can?(:online_correction, ScheduleEventFile, on: [@allocation_tag_id])}
    else
      render json: { success: false, alert: errors.flatten.uniq.join(';') }, status: :unprocessable_entity
    end
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid
    render json: { success: false, alert: t('schedule_event_files.error.general_error') }, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'schedule_event_files.error', 'new')
  end

  def online_correction
    authorize! :online_correction, ScheduleEventFile, on: active_tab[:url][:allocation_tag_id]
    @canvas_data = ScheduleEventFile.find(params[:id]).file_correction.to_json
    @file_name = params[:file]
    extension = params[:extension].split('/').last
    @file_path = get_file_path(id: params[:id], file: params[:file], extension: extension)
  end

  def save_online_correction_file
    authorize! :online_correction, ScheduleEventFile, on: active_tab[:url][:allocation_tag_id]
    @schedule_event_file = ScheduleEventFile.find(params[:id])
    @schedule_event_file.file_correction = params[:imgs]

    if @schedule_event_file.save
      render json: { success: true, notice: t('schedule_event_files.success.file_saved') }
    else
      render json: { success: false, alert: t('schedule_event_files.error.file_not_saved') }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :create, ScheduleEventFile, on: [active_tab[:url][:allocation_tag_id]]

    @schedule_event_file = ScheduleEventFile.find(params[:id])

    raise CanCan::AccessDenied if @schedule_event_file.user_id != current_user.id

    @schedule_event_file.destroy

    render json: { success: true, notice: t('schedule_event_files.success.deleted') }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'schedule_event_files.error', 'error')
  end

  def can_download
    verify_download

    if !@is_observer_or_responsible && @owner && Exam.verify_blocking_content(current_user.id)
      redirect_to schedule_events_path, alert: t('schedule_events.restrict_events')
    else
      render json: { success: true, url: (params[:id].blank? ? zip_download_schedule_event_files_path(event_id: @event.id) : download_schedule_event_files_path(event_id: @event.id, id: params[:id]) ) }
    end
  rescue => error
    render json: { success: false, alert: t('schedule_event_files.error.cant_download') }, status: :unprocessable_entity
  end

  def can_download
    verify_download

    if !@is_observer_or_responsible && @owner && Exam.verify_blocking_content(current_user.id)
      redirect_to schedule_events_path, alert: t('schedule_events.restrict_events')
    else
      render json: { success: true, url: (params[:id].blank? ? zip_download_schedule_event_files_path(event_id: @event.id) : download_schedule_event_files_path(event_id: @event.id, id: params[:id]) ) }
    end
  rescue => error
    render json: { success: false, alert: t('schedule_event_files.error.cant_download') }, status: :unprocessable_entity
  end

  def download
    verify_download

    if !@is_observer_or_responsible && @owner && Exam.verify_blocking_content(current_user.id)
      redirect_to schedule_events_path, alert: t('schedule_events.restrict_events')
    else
      if params[:zip].present?
        schedule_event_files = ScheduleEventFile.get_all_event_files(params[:event_id])
        path_zip = compress_file({ files: schedule_event_files, table_column_name: 'attachment_file_name', name_zip_file: @event.title })
      else
        path_zip  = @file.attachment.path
        file_name = @file.attachment_file_name
      end

      download_file(:back, path_zip, file_name)
    end
  end

  def delete_online_correction_canvas
    authorize! :online_correction, ScheduleEventFile, on: active_tab[:url][:allocation_tag_id]
    @schedule_event_file = ScheduleEventFile.find(params[:id])
    @schedule_event_file.file_correction = nil

    if @schedule_event_file.save
      render json: { success: true, notice: t('schedule_event_files.success.file_cleaned') }
    else
      render json: { success: false, alert: t('schedule_event_files.error.file_not_cleaned') }, status: :unprocessable_entity
    end
  end

  def summary
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    ac_id = (params[:ac_id].blank? ? AcademicAllocation.where(academic_tool_type: 'ScheduleEvent', academic_tool_id: (params[:tool_id]), allocation_tag_id: @allocation_tag_id).first.try(:id) : params[:ac_id])

    user_id = (params[:user_id].blank? ? current_user.id : params[:user_id])
    @acu = AcademicAllocationUser.find_or_create_one(ac_id, @allocation_tag_id, user_id, params[:group_id], false, nil)

    @files = ScheduleEventFile.where(academic_allocation_user_id: @acu.id)
    @tool = ScheduleEvent.find(params[:tool_id])

    render partial: 'summary'
  end

  private

    def verify_download
      @event = ScheduleEvent.find(params[:event_id])
      @file = ScheduleEventFile.find(params[:id]) rescue nil

      @is_observer_or_responsible = AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
      @owner = (@file.blank? ? false : @file.academic_allocation_user.user_id == current_user.id)

      raise CanCan::AccessDenied if !@owner && !@is_observer_or_responsible
    end

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

      []
    rescue => error
      @schedule_event_file.errors.full_messages
    end

    def create_many
      errors = []
      ScheduleEventFile.transaction do
        unless params[:files].blank?
          @schedule_event_files = []
          params[:files].each do |file|
            errors << create_one(schedule_event_file_params.merge!(attachment: file))
          end
        else
          errors << t('schedule_event_files.error.attachment_file_size_too_big', file: ScheduleEventFile::FILESIZE)
        end
      end
      errors
    rescue => error
      raise error
    end
end
