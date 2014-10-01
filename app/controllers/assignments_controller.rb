class AssignmentsController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper

  before_filter :prepare_for_group_selection, only: :list
  before_filter :get_ac, only: :evaluate
  layout false, except: [:list, :student]

  def index
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :index, Assignment, on: @allocation_tags_ids

    @assignments = Assignment.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).order("name").uniq
  end

  def new
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.new
    @assignment.build_schedule(start_date: Date.current, end_date: Date.current)
    @assignment.enunciation_files.build

    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids.split(" ")].flatten}).map(&:code).uniq
  end

  def edit
    authorize! :update, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.find(params[:id])
    @assignment.enunciation_files.build if @assignment.enunciation_files.empty?

    @enunciation_files = @assignment.enunciation_files.compact
    @schedule, @groups_codes = @assignment.schedule, @assignment.groups.pluck(:code)
  end

  def create
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @assignment = Assignment.new params[:assignment]

    Assignment.transaction do
      @assignment.save!
      @assignment.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
    end

    render json: {success: true, notice: t(:created, scope: [:assignments, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue => error
    @error = error.to_s.start_with?("academic_allocation") ? error.to_s.gsub("academic_allocation", "") : nil

    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
    @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
    @allocation_tags_ids = @allocation_tags_ids.join(" ")

    render :new
  end

  def update
    @allocation_tags_ids, @assignment = params[:allocation_tags_ids], Assignment.find(params[:id])
    authorize! :update, Assignment, on: @assignment.academic_allocations.pluck(:allocation_tag_id)

    @assignment.update_attributes!(params[:assignment])

    render json: {success: true, notice: t(:updated, scope: [:assignments, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    @groups_codes = @assignment.groups.pluck(:code)
    @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
    render :edit
  end

  def destroy
    @allocation_tags_ids, assignments = params[:allocation_tags_ids], Assignment.includes(:sent_assignments).where(id: params[:id].split(",").flatten, sent_assignments: {id: nil})
    authorize! :destroy, Assignment, on: assignments.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    Assignment.transaction do
      raise "error" if assignments.empty?
      assignments.destroy_all
    end

    render json: {success: true, notice: t(:deleted, scope: [:assignments, :success])}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render json: {success: false, alert: t(:deleted, scope: [:assignments, :error])}, status: :unprocessable_entity
  end

  def show
    authorize! :show, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @assignment = Assignment.find(params[:id])
    @enunciation_files, @groups_codes = @assignment.enunciation_files.compact, @assignment.groups.pluck(:code)
  end

  def list
    authorize! :list, Assignment, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @student = not(AllocationTag.find(@allocation_tag_id).is_observer_or_responsible?(current_user.id))
    @public_files = PublicFile.where(user_id: current_user.id, allocation_tag_id: @allocation_tag_id)
    @assignments  = Assignment.joins(:academic_allocations, :schedule).where(academic_allocations: {allocation_tag_id:  @allocation_tag_id})
                              .select("assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date").order("start_date")
    @participants = AllocationTag.get_students(@allocation_tag_id)
    @can_manage, @can_import = (can? :index, GroupAssignment, on: [@allocation_tag_id]), (can? :import, GroupAssignment, on: [@allocation_tag_id])

    render layout: false if params[:layout].present?
  end

  def student
    @assignment, @allocation_tag_id = Assignment.find(params[:id]), active_tab[:url][:allocation_tag_id]
    @class_participants = AllocationTag.get_students(@allocation_tag_id)
    @student_id, @group_id = (params[:group_id].nil? ? [params[:student_id], nil] : [nil, params[:group_id]])
    @group = GroupAssignment.find(params[:group_id]) unless @group_id.nil?
    @own_assignment = Assignment.owned_by_user?(current_user.id, {student_id: @student_id, group: @group})
    raise CanCan::AccessDenied unless @own_assignment or AllocationTag.find(@allocation_tag_id).is_observer_or_responsible?(current_user.id)
    @in_time = @assignment.in_time?(@allocation_tag_id, current_user.id)

    @sent_assignment = @assignment.sent_assignment_by_user_id_or_group_assignment_id(@allocation_tag_id, @student_id, @group_id)
  end

  def evaluate
    @assignment, @allocation_tag_id = Assignment.find(params[:id]), active_tab[:url][:allocation_tag_id]
    authorize! :evaluate, Assignment, on: [@allocation_tag_id]
    raise "date_range" unless @in_time = @assignment.in_time?(@allocation_tag_id, current_user.id)

    @sent_assignment = SentAssignment.where(user_id: params[:student_id], group_assignment_id: params[:group_id], academic_allocation_id: @ac).first_or_create
    @sent_assignment.update_attributes! grade: params[:grade].tr(",", ".")

    @student_id, @group_id = params[:student_id], params[:group_id]

    LogAction.create(log_type: LogAction::TYPE[(@sent_assignment.previous_changes.has_key?(:id) ? :create : :update)], user_id: current_user.id, ip: request.remote_ip, description: "sent_assignment: #{@sent_assignment.attributes.merge({"assignment_id" => @assignment.id})}") rescue nil

    render json: { success: true, notice: t("assignments.success.evaluated"), html: "#{render_to_string(partial: "info")}" }
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render_json_error(error, "assignments.error", "evaluate", error.message)
  end

  def download
    authorize! :download, Assignment, on: [active_tab[:url][:allocation_tag_id]]
    if params[:zip].present?
      assignment = Assignment.find(params[:assignment_id])
      path_zip = compress({ files: assignment.enunciation_files, table_column_name: 'attachment_file_name', name_zip_file: assignment.name })
      download_file(:back, path_zip)
    else
      file = AssignmentEnunciationFile.find(params[:id])
      download_file(:back, file.attachment.path, file.attachment_file_name)
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render js: "flash_message('#{t(:file_error_nonexistent_file)}', 'alert');"
  end

end
