class GroupAssignmentsController < ApplicationController

  include SysLog::Actions
  include AssignmentsHelper

  before_filter :set_current_user, only: [:destroy, :change_participant]
  before_filter :get_ac, only: [:create, :import, :list]

  layout false

  def index
    @assignment, allocation_tag_id = Assignment.find(params[:assignment_id]), active_tab[:url][:allocation_tag_id]
    @groups, @students_without_group = @assignment.groups_assignments(allocation_tag_id), @assignment.students_without_groups(allocation_tag_id)
  end

  def list
    @groups = @ac.group_assignments
  end

  def show
    render partial: "group", locals: {group: GroupAssignment.find(params[:id])}
  end

  def create
    authorize! :index, GroupAssignment, on: [active_tab[:url][:allocation_tag_id]]

    @group_assignment = GroupAssignment.create!({academic_allocation_id: @ac.id, group_name: t("group_assignments.new.new_group_name")})
    render :new
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t("group_assignments.error.general_message")}, status: :unprocessable_entity
  end

  def edit
    @group_assignment = GroupAssignment.find(params[:id])
  end

  def update
    authorize! :index, GroupAssignment, on: [active_tab[:url][:allocation_tag_id]]

    @group_assignment = GroupAssignment.find(params[:id])

    if @group_assignment.update_attributes(group_assignment_params)
      render json: {success: true}
    else
      render json: {success: false, alert: @group_assignment.errors.full_messages.join}, status: :unprocessable_entity
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def change_participant
    authorize! :index, GroupAssignment, on: [active_tab[:url][:allocation_tag_id]]

    @participant = GroupParticipant.where(group_assignment_id: params[:id], user_id: params[:user_id]).first_or_create!
    @participant.destroy unless params[:add].present?

    render json: {success: true}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render_json_error(error, "group_assignments.error")
  end

  def destroy
    authorize! :index, GroupAssignment, on: [active_tab[:url][:allocation_tag_id]]

    @group_assignment = GroupAssignment.find(params[:id])
    @group_assignment.destroy

    render json: {success: true}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render_json_error(error, "group_assignments.error")
  end

  def participants
    @participants, @import = GroupAssignment.find(params[:id]).users, params[:import].present?
  end

  def students_with_no_group
    students_without_group = Assignment.find(params[:assignment_id]).students_without_groups(active_tab[:url][:allocation_tag_id])
    render partial: "students_with_no_group", locals: {students: students_without_group}
  end

  def import_list
    @assignment, @allocation_tag_id  = Assignment.find(params[:assignment_id]), active_tab[:url][:allocation_tag_id]
    @assignments = Assignment.joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: @allocation_tag_id}, assignments: {type_assignment: Assignment_Type_Group}).reject{|a| a.id == @assignment.id}
  end

  def import
    authorize! :import, GroupAssignment, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @ac.copy_group_assignments(AcademicAllocation.where(academic_tool_type: "Assignment", academic_tool_id: params[:id], allocation_tag_id: allocation_tag_id).first.id)
    render json: {success: true, notice: t("group_assignments.success.imported")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue => error
    render_json_error(error, "group_assignments.error")
  end

  private

    def group_assignment_params
      params.require(:group_assignment).permit(:group_name)
    end

end
