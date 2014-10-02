class ScoresController < ApplicationController

  before_filter :prepare_for_group_selection, only: :index
  before_filter :prepare_for_pagination, only: :index

  def index
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @group = AllocationTag.find(@allocation_tag_id).groups.first

    @assignments = Assignment.joins(:schedule, {academic_allocations: :allocation_tag}).where(allocation_tags: {id: @allocation_tag_id})
      .order("schedules.start_date, assignments.name")
    @students    = AllocationTag.get_students(@allocation_tag_id)
  end

  def info
    authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @student = current_user
    informations(@allocation_tag_id)
  end

  def student_info
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @student = User.find(params[:student_id])
    informations(@allocation_tag_id)
    render :info
  end

  def amount_access
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    begin
      raise CanCan::AccessDenied unless params[:user_id] == current_user.id
    rescue
      authorize! :index, Score, on: [allocation_tag_id]
    end

    query = []
    query << "date(created_at) >= '#{params['from-date'].to_date}'" unless params['from-date'].blank?
    query << "date(created_at) <= '#{params['until-date'].to_date}'" unless params['until-date'].blank?

    @access = LogAccess.where(log_type: LogAccess::TYPE[:offer_access], user_id: params[:user_id], allocation_tag_id: AllocationTag.find(allocation_tag_id).related).where(query.join(" AND ")).order("created_at DESC")

    render partial: "access"

  rescue CanCan::AccessDenied
    render json: {alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {alert: t("scores.error.invalid_date")}, status: :unauthorized
  end

  private
    def informations(allocation_tag_id)
      @assignments = Assignment.joins(:academic_allocations, :schedule).where(academic_allocations: {allocation_tag_id:  allocation_tag_id})
                               .select("assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date").order("start_date")
      @discussions = Discussion.posts_count_by_user(@student.id, allocation_tag_id)
      @access      = LogAccess.where(log_type: LogAccess::TYPE[:offer_access], user_id: @student.id, allocation_tag_id: AllocationTag.find(allocation_tag_id).related).order("created_at DESC")
    end

end
