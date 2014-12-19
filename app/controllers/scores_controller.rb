class ScoresController < ApplicationController

  before_filter :prepare_for_group_selection, only: :index
  before_filter :prepare_for_pagination, only: :index

  def index
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @group = AllocationTag.find(@allocation_tag_id).groups.first

    @assignments = Assignment.joins(:schedule, {academic_allocations: :allocation_tag}).where(allocation_tags: {id: @allocation_tag_id})
      .order("schedules.start_date, assignments.name")
    @students     = AllocationTag.get_participants(@allocation_tag_id, {students: true})
    @responsibles = AllocationTag.get_participants(@allocation_tag_id, {responsibles: true, profiles: Profile.with_access_on("create", "posts").join(",")}) if current_user.profiles_with_access_on("responsibles", "scores", AllocationTag.find(@allocation_tag_id).related).any?
  end

  def info
    authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = current_user
    @assignments, @discussions, @access = Score.informations(@user.id, @allocation_tag_id, type_hash: false)
  end

  def user_info
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = User.find(params[:user_id])
    @assignments, @discussions, @access = Score.informations(@user.id, @allocation_tag_id, type_hash: false)
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

    @access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: params[:user_id], allocation_tag_id: AllocationTag.find(allocation_tag_id).related).where(query.join(" AND "))

    render partial: "access"

  rescue CanCan::AccessDenied
    render json: {alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {alert: t("scores.error.invalid_date")}, status: :unauthorized
  end

end
