class AssignmentsController < ApplicationController

  include SysLog::Actions
  include FilesHelper
  include AssignmentsHelper
  include Bbb
  include IpRealHelper

  before_filter :prepare_for_group_selection, only: :list
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

    at = AllocationTag.find(@allocation_tag_id)

    @student      = !at.is_observer_or_responsible?(current_user.id)
    @public_files = PublicFile.where(user_id: current_user.id, allocation_tag_id: @allocation_tag_id)

    @assignments_indiv = Score.list_tool(current_user.id, @allocation_tag_id, 'assignments', false, false, true, false, Assignment_Type_Individual)
    @assignments_group = Score.list_tool(current_user.id, @allocation_tag_id, 'assignments', false, false, true, false, Assignment_Type_Group)

    user_profiles = current_user.resources_by_allocation_tags_ids([@allocation_tag_id])

    offer_ok = at.verify_offer_period

    @can_manage   = user_profiles.include?(group_assignments: :index) && offer_ok
    @can_import   = user_profiles.include?(group_assignments: :import) && offer_ok
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
    @assignment.ip_reals.build
  end

  def edit
    authorize! :update, Assignment, on: @allocation_tags_ids
    @assignment.enunciation_files.build if @assignment.enunciation_files.empty?
    @assignment.ip_reals.build if @assignment.ip_reals.empty?
  end

  def create
    authorize! :create, Assignment, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @assignment = Assignment.new assignment_params
    @assignment.allocation_tag_ids_associations = @allocation_tags_ids.split(" ").flatten
    @assignment.schedule.verify_today = true

    @assignment.save!
    GroupAssignment.split_students_in_groups(@assignment.id)
    render_assignment_success_json('created')

  rescue => error
    if @assignment.errors.empty?
      render_json_error(error, 'assignments.error')
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
    render_json_error(error, 'assignments.error')
  end

  def destroy
    @assignments = Assignment.where(id: params[:id].split(',').flatten)
    authorize! :destroy, Assignment, on: @assignments.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    evaluative = @assignments.map(&:verify_evaluatives).include?(true)
    if @assignments.map(&:can_remove_groups?).include?(true)
      Assignment.transaction do
        @assignments.destroy_all
      end

      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:assignments, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    else
      render_json_error('dependencies', 'assignments.error')
    end
  rescue => error
    render_json_error(error, 'assignments.error')
  end

  def student
    @assignment, @allocation_tag_id = Assignment.find(params[:id]), active_tab[:url][:allocation_tag_id]
    if Exam.verify_blocking_content(current_user.id)
      redirect_to list_assignments_path, alert: t('assignments.restrict_assignment')
    else
      assignment_started?(@assignment)
      verify_owner_or_responsible!(@allocation_tag_id, nil, :html)
      @class_participants             = AllocationTag.get_participants(@allocation_tag_id, { students: true }).map(&:id)

      @in_time = @assignment.in_time?(@allocation_tag_id, current_user.id)
      @ac = AcademicAllocation.where(academic_tool_id: @assignment.id, allocation_tag_id: @allocation_tag_id, academic_tool_type: 'Assignment').first
      @can_evaluate = can?(:evaluate, Assignment, on: [@allocation_tag_id] )

      @acu = AcademicAllocationUser.find_one(@ac.id, @student_id, @group_id, false, @can_evaluate)

      allocations = Allocation.where(allocation_tag_id: @allocation_tag_id)
      all = allocations.select{|a| a.user_id == current_user.id}
      current_user_profiles = Profile.find(all.map{|a| a.profile_id})
      @not_only_student_profile = current_user_profiles.any?{ |p| p.types != Profile_Type_Student}
      @only_student_profile = current_user_profiles.any?{ |p| p.types == Profile_Type_Student}

      if @group.individually_graded
        @acu.remove_grade_and_working_hours
        @individually_graded_acus = set_academic_allocation_user_for_individually_graded(@ac.id, @allocation_tag_id, @group)
        @student_id = params[:student_id]
      end

    end
  rescue CanCan::AccessDenied
    redirect_to list_assignments_path, alert: t(:no_permission)
  rescue => error
    redirect_to list_assignments_path, alert: (error.to_s == 'not_started' ? t('assignments.error.not_started2') : t('assignments.error.general_message'))
  end

  def summarized
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    if (current_user.is_student?([@allocation_tag_id]) && Exam.verify_blocking_content(current_user.id))
      render text: t('exams.restrict')
    else
      @assignment = Assignment.find(params[:id])
      @score_type = params[:score_type]
      verify_owner_or_responsible!(@allocation_tag_id, nil, :text)
      @class_participants             = AllocationTag.get_participants(@allocation_tag_id, { students: true }).map(&:id)
      @in_time = @assignment.in_time?(@allocation_tag_id, current_user.id)

      @ac = AcademicAllocation.where(academic_tool_id: @assignment.id, allocation_tag_id: @allocation_tag_id, academic_tool_type: 'Assignment').first
      @can_evaluate = can?(:evaluate, Assignment, on: [@allocation_tag_id] )
      @frequency = @can_evaluate && @ac.frequency

      @acu = AcademicAllocationUser.find_one(@ac.id, @student_id, @group_id, false, @can_evaluate)
    end
  rescue CanCan::AccessDenied
    render text: t(:no_permission)
  end

  def download
    if params[:zip].present?
      assignment = Assignment.find(params[:assignment_id])
    else
      file = AssignmentEnunciationFile.find(params[:id])
      assignment = Assignment.find(file.assignment_id)
    end
    if Exam.verify_blocking_content(current_user.id)
      redirect_to :back, alert: t('exams.restrict')
    else
      verify_ip!(assignment.id, :assignment, assignment.controlled, :raise) unless AllocationTag.find(allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id) || assignment.ended?
      authorize! :download, Assignment, on: [allocation_tag_id]
      if params[:zip].present?
        assignment_started?(assignment)
        path_zip = compress_file({ files: assignment.enunciation_files, table_column_name: 'attachment_file_name', name_zip_file: assignment.name })
        download_file(:back, path_zip || nil)
      else
        assignment_started?(file.assignment)
        download_file(:back, file.attachment.path, file.attachment_file_name)
      end
    end
    rescue CanCan::AccessDenied
      redirect_to list_assignments_path, alert: t(:no_permission)
    rescue => error
      redirect_to :back, alert: (error.to_s == 'not_started' ? t('assignments.error.not_started') : t('assignments.error.download'))
  end

  def participants
    raise CanCan::AccessDenied unless AllocationTag.find(@allocation_tag_id = active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
    assignment = Assignment.find(params[:id])
    @participants = AllocationTag.get_participants(@allocation_tag_id, { students: true })
    render partial: (assignment.type_assignment == Assignment_Type_Group ? 'groups' : 'participants'), locals: { assignment: assignment }
  end

  def individually_graded
    authorize! :evaluate, Assignment, on: [at_id = active_tab[:url][:allocation_tag_id]]

    group = GroupAssignment.find(params[:group_id])
    group.individually_graded = params[:individually_graded]
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    if group.save
      ac = AcademicAllocation.where(academic_tool_id: params[:id], allocation_tag_id: allocation_tag_id, academic_tool_type: 'Assignment').first

      if group.individually_graded
        acu_group = AcademicAllocationUser.where(academic_allocation_id: ac.id, group_assignment_id: group.id).first
        acu_group.remove_grade_and_working_hours

        individually_graded_acus = set_academic_allocation_user_for_individually_graded(ac.id, allocation_tag_id, group)
        assignment = Assignment.find(params[:id])

        students_info = []

        individually_graded_acus.each do |acu|
          info = assignment.info(acu.user_id, allocation_tag_id, group.id)
          students_info << {"student_id" => acu.user_id, "student_name" => acu.user_name, "start_date" => l(assignment.schedule.start_date, format: :normal), "end_date" => l(assignment.schedule.end_date, format: :normal), "student_situation" => t(info[:situation].to_sym), "student_grade" => acu.grade, "student_working_hours" => acu.working_hours, "id" => assignment.id, "max_wh" => ac.max_working_hours}
        end
      else
        remove_acu_for_group_assignments(ac.id, group)
      end

      render json: { success: true, notice: t(group.individually_graded ? 'individually' : 'not_individually', scope: [:assignments, :success]), students_info: students_info}
    else
      render json: { success: false, alert: t('assignments.error.individually_error') }, status: :unprocessable_entity
    end
  end

  private

    def assignment_params
      params.require(:assignment).permit(:name, :enunciation, :type_assignment, :start_hour, :end_hour, :controlled,
        schedule_attributes: [:id, :start_date, :end_date],
        enunciation_files_attributes: [:id, :attachment, :_destroy],
        ip_reals_attributes: [:id, :ip_v4, :ip_v6, :_destroy])
    end

    def render_assignment_success_json(method)
      render json: {success: true, notice: t(method, scope: 'assignments.success')}
    end

    def assignment_started?(assignment)
      raise "not_started" unless assignment.started? || AllocationTag.find(active_tab[:url][:allocation_tag_id]).is_observer_or_responsible?(current_user.id)
    end

    def set_academic_allocation_user_for_individually_graded(academic_allocation_id, allocation_tag_id, group)
      individually_graded_acus = []

      group.users.each do |student|
        individually_graded_acu = AcademicAllocationUser.where(academic_allocation_id: academic_allocation_id, user_id: student.id).first_or_create
        individually_graded_acu.user_name = student.name
        individually_graded_acus << individually_graded_acu
      end

      individually_graded_acus
    end

    def remove_acu_for_group_assignments(academic_allocation_id, group)
      group.users.each do |student|
        acu = AcademicAllocationUser.where(academic_allocation_id: academic_allocation_id, user_id: student.id).first
        acu.delete unless acu.nil?
      end
    end

end
