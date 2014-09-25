class GroupAssignmentsController < ApplicationController

  include SysLog::Actions

  layout false

  def index
    @assignment, allocation_tag_id = Assignment.find(params[:assignment_id]), active_tab[:url][:allocation_tag_id]
    @groups = GroupAssignment.all_by_assignment_id(@assignment.id, allocation_tag_id)
    @students_without_group = @assignment.students_without_groups(AllocationTag.find(allocation_tag_id))
  end

  def participants
    @participants, @import = GroupAssignment.find(params[:id]).users, params[:import].present?
  end

  def create
    authorize! :index, GroupAssignment, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    ac = AcademicAllocation.where(academic_tool_id: params[:assignment_id], academic_tool_type: "Assignment", allocation_tag_id: allocation_tag_id).first.id
    attributes, count = {academic_allocation_id: ac, group_name: t("group_assignments.new.new_group_name")}, 1
    @group = GroupAssignment.where(attributes).first_or_initialize

    until @group.new_record?
      @group = GroupAssignment.where(attributes.merge({group_name: "#{t("group_assignments.new.new_group_name")} #{count}"})).first_or_initialize
      count += 1
    end
    
    @group.save!

    render :new
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  rescue
    render json: {success: false, alert: t("group_assignments.error.general_message")}, status: :unprocessable_entity
  end

  def change_participant
    authorize! :index, GroupAssignment, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    
    group = GroupAssignment.find(params[:id])

    raise "date_range_expired" unless group.assignment.in_time?(allocation_tag_id, current_user.id)
    raise "evaluated" if group.evaluated?

    participant = GroupParticipant.where(group_assignment_id: group.id, user_id: params[:user_id]).first_or_create
    unless params[:add].present?
      files = group.sent_assignment.try(:assignment_files)
      raise "has_files" if (not(files.nil?) and files.any?) and files.map(&:user_id).include? params[:user_id].to_i
      participant.destroy 
    end

    render json: {success: true}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  rescue => error
    error_message = I18n.translate!("group_assignments.error.#{error.message}", raise: true) rescue t("group_assignments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity
  end

  def edit
    @group_assignment = GroupAssignment.find(params[:id])
  end

  def update
    authorize! :index, GroupAssignment, on: [active_tab[:url][:allocation_tag_id]]

    GroupAssignment.find(params[:id]).update_attributes!(params[:group_assignment])

    render json: {success: true}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  rescue => error
    render json: {success: false, alert: error.message}, status: :unprocessable_entity 
  end

  def show
    render partial: "group", locals: {group: GroupAssignment.find(params[:id])}
  end

  def destroy
    authorize! :index, GroupAssignment, on: [active_tab[:url][:allocation_tag_id]]

    group = GroupAssignment.find(params[:id])
    raise "cant_remove" unless group.can_remove?
    if group.destroy
      render json: {success: true}
    else
      render json: {success: false, alert: t("group_assignments.error.general_message")}, status: :unprocessable_entity 
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  rescue => error
    error_message = I18n.translate!("group_assignments.error.#{error}", raise: true) rescue t("group_assignments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity 
  end

  def students_with_no_group
    assignment = Assignment.find(params[:assignment_id])
    students_without_group = assignment.students_without_groups(AllocationTag.find(active_tab[:url][:allocation_tag_id]))
    render partial: "students_with_no_group", locals: {students: students_without_group}
  end
  
  def import_list
    @assignment, @allocation_tag_id  = Assignment.find(params[:assignment_id]), active_tab[:url][:allocation_tag_id]
    @assignments = Assignment.joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: @allocation_tag_id}, assignments: {type_assignment: Assignment_Type_Group}).reject{|a| a.id == @assignment.id}
  end

  def list
    @groups = AcademicAllocation.where(academic_tool_id: params[:assignment_id], academic_tool_type: "Assignment", allocation_tag_id: active_tab[:url][:allocation_tag_id]).first.group_assignments
  end

  def import
    authorize! :import, GroupAssignment, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    raise "date_range_expired" unless Assignment.find(params[:id]).in_time?(allocation_tag_id, current_user.id)

    from_ac  = AcademicAllocation.where(academic_tool_type: "Assignment", academic_tool_id: params[:assignment_id], allocation_tag_id: allocation_tag_id).first
    to_ac_id = AcademicAllocation.where(academic_tool_type: "Assignment", academic_tool_id: params[:id], allocation_tag_id: allocation_tag_id).first.id

    ActiveRecord::Base.transaction do
      from_ac.group_assignments.each do |group|
        new_group = GroupAssignment.where(group_name: group.group_name, academic_allocation_id: to_ac_id).first_or_create
        group.group_participants.each do |participant|
          GroupParticipant.where(user_id: participant.user_id, group_assignment_id: new_group.id).first_or_create
        end
      end
    end
    render json: {success: true, notice: t("group_assignments.success.imported")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unprocessable_entity
  rescue => error
    error_message = I18n.translate!("group_assignments.error.#{error}", raise: true) rescue t("group_assignments.error.general_message")
    render json: {success: false, alert: error_message}, status: :unprocessable_entity 
  end

end
