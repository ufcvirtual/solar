class AssignmentsController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper
  include Bbb

  before_filter :prepare_for_group_selection, only: :list
  before_filter :get_ac, only: :evaluate
  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  before_filter :set_current_user, only: :student

  before_filter only: [:edit, :update, :show] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@assignment = Assignment.find(params[:id]))
  end

  layout false, except: [:list, :student]

  def index
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :index, Assignment, on: @allocation_tags_ids

    @assignments = Assignment.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).select("assignments.*, schedules.start_date AS sd").order("sd, name").uniq
  end

  def list
    authorize! :list, Assignment, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @student      = !AllocationTag.find(@allocation_tag_id).is_observer_or_responsible?(current_user.id)
    @public_files = PublicFile.where(user_id: current_user.id, allocation_tag_id: @allocation_tag_id)
    

    @assignments  = Assignment.joins(:academic_allocations, :schedule).where(academic_allocations: { allocation_tag_id:  @allocation_tag_id })
                              .select("assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date").order("start_date")

    @participants = AllocationTag.get_participants(@allocation_tag_id, { students: true })

    user_profiles = current_user.resources_by_allocation_tags_ids([@allocation_tag_id])

    @can_manage   = user_profiles.include?(group_assignments: :index)
    @can_import   = user_profiles.include?(group_assignments: :import)
    @can_evaluate = user_profiles.include?(assignments: :evaluate)

    render layout: false if params[:layout].present?
  end

  def show
    authorize! :show, Assignment, on: @allocation_tags_ids
  end

  def new
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.new
    @assignment.build_schedule(start_date: Date.today, end_date: Date.today)
    @assignment.enunciation_files.build
  end

  def edit
    authorize! :update, Assignment, on: @allocation_tags_ids
    @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
  end

  def create
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.new assignment_params
    @assignment.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten

    @assignment.save!
    render_assignment_success_json('created')
  rescue => error
    if @assignment.errors.empty?
      request.format = :json
      raise error.class
    else
      @files_errors = @assignment.enunciation_files.compact.map(&:errors).map(&:full_messages).flatten.uniq.join(', ')
      @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
      render :new
    end
  end

  def update
    authorize! :update, Assignment, on: @assignment.academic_allocations.pluck(:allocation_tag_id)
    if @assignment.update_attributes(assignment_params)
      render_assignment_success_json('updated')
    else
      @files_errors = @assignment.enunciation_files.compact.map(&:errors).map(&:full_messages).flatten.uniq.join(', ')
      @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @assignments = Assignment.includes(:sent_assignments).where(id: params[:id].split(',').flatten, sent_assignments: {id: nil})
    authorize! :destroy, Assignment, on: @assignments.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    @assignments.destroy_all
    render_assignment_success_json('deleted')
  rescue => error
    request.format = :json
    raise error.class
  end

  def student

    if user_session[:blocking_content]
      redirect_to list_assignments_path, alert: t('exams.restrict')
    else
      @assignment, @allocation_tag_id = Assignment.find(params[:id]), active_tab[:url][:allocation_tag_id]
      @class_participants             = AllocationTag.get_participants(@allocation_tag_id, { students: true }).map(&:id)
      verify_owner_or_responsible!(@allocation_tag_id)

      @in_time = @assignment.in_time?(@allocation_tag_id, current_user.id)

      @sent_assignment = @assignment.sent_assignment_by_user_id_or_group_assignment_id(@allocation_tag_id, @student_id, @group_id)
      @can_evaluate = can?(:evaluate, Assignment, on:  [@allocation_tag_id] )
      @bbb_online   = bbb_online?
    end  
  end

  def evaluate
    @assignment, @allocation_tag_id = Assignment.find(params[:id]), active_tab[:url][:allocation_tag_id]
    authorize! :evaluate, Assignment, on: [@allocation_tag_id]
    raise 'date_range' unless @in_time = @assignment.in_time?(@allocation_tag_id, current_user.id)

    @sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: @ac).first_or_initialize
    @sent_assignment.can_create = true
    @sent_assignment.grade      = params[:grade].tr(',', '.')
    @sent_assignment.save!

    @student_id, @group_id = params[:student_id], params[:group_id]

    LogAction.create(log_type: LogAction::TYPE[(@sent_assignment.previous_changes.has_key?(:id) ? :create : :update)], user_id: current_user.id, ip: request.remote_ip, description: "sent_assignment: #{@sent_assignment.attributes.merge({"assignment_id" => @assignment.id})}",allocation_tag_id:@allocation_tag_id, academic_allocation_id: AcademicAllocation.select(:id).find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(@allocation_tag_id,@sent_assignment.id,'Assignment') ) rescue nil

    @can_evaluate = true

    render json: { success: true, notice: t('assignments.success.evaluated'), html: "#{render_to_string(partial: "info")}" }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'assignments.error', 'evaluate', error.message)
  end

  def download
    if Exam.verify_blocking_content(current_user.id)
      redirect_to :back, alert: t('exams.restrict')
    else
      authorize! :download, Assignment, on: [active_tab[:url][:allocation_tag_id]]
      if params[:zip].present?
        assignment = Assignment.find(params[:assignment_id])
        path_zip = compress({ files: assignment.enunciation_files, table_column_name: 'attachment_file_name', name_zip_file: assignment.name })
        download_file(:back, path_zip || nil)
      else
        file = AssignmentEnunciationFile.find(params[:id])
        download_file(:back, file.attachment.path, file.attachment_file_name)
      end
    end  
  end

  private

    def assignment_params
      params.require(:assignment).permit(:name, :enunciation, :type_assignment, schedule_attributes: [:id, :start_date, :end_date], enunciation_files_attributes: [:id, :attachment, :_destroy])
    end

    def render_assignment_success_json(method)
      render json: {success: true, notice: t(method, scope: 'assignments.success')}
    end

end
