class ScoresController < ApplicationController

  include Bbb

  before_filter :prepare_for_group_selection, only: :index
  before_filter :prepare_for_pagination, only: :index

  def index
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @group = AllocationTag.find(@allocation_tag_id).groups.first

    @assignments = Assignment.joins(:schedule, { academic_allocations: :allocation_tag }).where(allocation_tags: { id: @allocation_tag_id })
      .order("schedules.start_date, assignments.name")
    @students     = AllocationTag.get_participants(@allocation_tag_id, { students: true }, true)
    @responsibles = AllocationTag.get_participants(@allocation_tag_id, { responsibles: true, profiles: Profile.with_access_on("create", "posts").join(",") }, true) if current_user.profiles_with_access_on("responsibles", "scores", AllocationTag.find(@allocation_tag_id).related).any?
  end

  def info
    authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = current_user

    @types = [ [t(:exam, scope: [:scores, :info]), 'exam'], [t(:assignments, scope: [:scores, :info]), 'assignment'],[t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat'],[t(:webconference, scope: [:scores, :info]), 'webconference'],[t(:schedule_events, scope: [:scores, :info]), 'schedule_event'], [t(:all, scope: [:scores, :info]), 'all']]

  
    @access, @public_files = Score.informations(@user.id, @allocation_tag_id)
  end

  def search_tool

    authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    ar_tool = params[:tool]
    t= ar_tool.length
    tool = ar_tool[t.to_i-1]
    puts @allocation_tag_id
      if tool == 'discussion'
        @can_evaluate = can? :evaluate, Discussion, { on: @allocation_tag_id }
        @discussions_evaluative     = Discussion.all_by_allocation_tags_evaluative(@allocation_tag_id, true)
        @discussions_frequency      = Discussion.all_by_allocation_tags_evaluative(@allocation_tag_id, false, true)
        @discussions_not_evaluative = Discussion.all_by_allocation_tags_evaluative(@allocation_tag_id)
        render partial: "scores/info/"+tool
      elsif tool == 'chat'
        @can_evaluate = can? :evaluate, ChatRoom, { on: @allocation_tag_id }
        chats_evaluative = ChatRoom.list_chats(@user.id, @allocation_tag_id, true)
        chats_frequency = ChatRoom.list_chats(@user.id, @allocation_tag_id,false, true)
        chats_not_evaluative = ChatRoom.list_chats(@user.id, @allocation_tag_id)

        @chats_evaluative = chats_evaluative[:my]
        @chats_frequency = chats_frequency[:my]
        @chats_not_evaluative = chats_not_evaluative[:my]
        render partial: "scores/info/"+tool, locals: { chats: @my_chats, history: true, can_open_link: true }
      elsif tool == 'webconference'  
        api = bbb_prepare
        @online = bbb_online?(api)
        @can_see_access = can? :evaluate, Webconference, { on: @allocation_tag_id }
       
        @webconferences_evaluative =  Webconference.all_by_allocation_tags(AllocationTag.find(@allocation_tag_id).related(upper: true), {asc: true}, (@can_see_access ? nil : @user.id), true, false)
        @webconferences_frequency = Webconference.all_by_allocation_tags(AllocationTag.find(@allocation_tag_id).related(upper: true), {asc: true}, (@can_see_access ? nil : @user.id), false, true)
        @webconferences_not_evaluative = Webconference.all_by_allocation_tags(AllocationTag.find(@allocation_tag_id).related(upper: true), {asc: true}, (@can_see_access ? nil : @user.id), true, true)
        render partial: "scores/info/"+tool
      elsif tool == 'exam'
        @can_see_access = can? :evaluate, Exam, { on: @allocation_tag_id }

        @exams_evaluative = Exam.list_exams(@allocation_tag_id, true)
        @exams_frequency = Exam.list_exams(@allocation_tag_id, false, true)
        @exams_not_evaluative = Exam.list_exams(@allocation_tag_id)
        render partial: "scores/info/"+tool
      elsif tool == 'assignment'
        @can_evaluate_ass = can? :evaluate, Assignment, { on: @allocation_tag_id }
        @assigments_evaluative = Assignment.list_assigment(@user.id, @allocation_tag_id, true) 
        @assigments_frequency = Assignment.list_assigment(@user.id, @allocation_tag_id, false, true) 
        @assigments_not_evaluative = Assignment.list_assigment(@user.id, @allocation_tag_id) 
        render partial: "scores/info/"+tool 
      elsif tool == 'schedule_event'
        @can_evaluate_ev = can? :evaluate, ScheduleEvent, { on: @allocation_tag_id }

        @schedules_event_evaluative = ScheduleEvent.list_schedule_event(@allocation_tag_id, true) 
        @schedules_event_frequency = ScheduleEvent.list_schedule_event(@allocation_tag_id, false, true) 
        @schedules_event_not_evaluative = ScheduleEvent.list_schedule_event(@allocation_tag_id) 
        render partial: "scores/info/"+tool 
      else  #todos
        @tool_evaluative = Score.list_tool(@user.id, @allocation_tag_id, true)
        @tool_frequency = Score.list_tool(@user.id, @allocation_tag_id, false, true) 
        @tool_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id) 
        render partial: "scores/info/"+tool
      end   

  end  

  def user_info
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = User.find(params[:user_id])
    @access, @public_files = Score.informations(@user.id, @allocation_tag_id)
    @types = [ [t(:exam, scope: [:scores, :info]), 'exam'], [t(:assignments, scope: [:scores, :info]), 'assignment'],[t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat'],[t(:webconference, scope: [:scores, :info]), 'webconference'],[t(:schedule_events, scope: [:scores, :info]), 'schedule_event'], [t(:all, scope: [:scores, :info]), 'all'] ]
    render :info
  end 

  def amount_access
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    begin
      raise CanCan::AccessDenied unless params[:user_id].to_i == current_user.id
    rescue
      authorize! :index, Score, on: [allocation_tag_id]
    end

    query = []
    query << "date(created_at) >= '#{params['from-date'].to_date}'"  unless params['from-date'].blank?
    query << "date(created_at) <= '#{params['until-date'].to_date}'" unless params['until-date'].blank?

    @access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: params[:user_id], allocation_tag_id: AllocationTag.find(allocation_tag_id).related).where(query.join(" AND "))

    render partial: "access"

  rescue CanCan::AccessDenied
    render json: {alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {alert: t("scores.error.invalid_date")}, status: :unauthorized
  end

end
