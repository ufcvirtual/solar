class ScoresController < ApplicationController

  include Bbb

  before_filter :prepare_for_group_selection, only: :index
  before_filter :prepare_for_pagination, only: :index

  layout false, only: :search_tool

  def index
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @group = AllocationTag.find(@allocation_tag_id).groups.first

    ats = AllocationTag.find(@allocation_tag_id).related.join(',')
    @responsibles = AllocationTag.get_participants(@allocation_tag_id, { responsibles: true, profiles: Profile.with_access_on("create", "posts").join(",") }, true) if current_user.profiles_with_access_on("responsibles", "scores", AllocationTag.find(@allocation_tag_id).related).any?

    @users = AllocationTag.get_participants(@allocation_tag_id, { students: true }, true)
    @tools = ( ats.empty? ? [] : EvaluativeTool.count_tools(ats) )
    @wh = AllocationTag.find(@allocation_tag_id).get_curriculum_unit.try(:working_hours)
  end

  def evaluatives_frequency
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    @wh = AllocationTag.find(@allocation_tag_id).get_curriculum_unit.try(:working_hours)

    query = case params[:type]
            when 'frequency'; 'ac.frequency = true'
            when 'evaluative'; 'ac.evaluative = true'
            else
              '(ac.evaluative = false OR ac.evaluative IS NULL)'
            end

    ats = AllocationTag.find(@allocation_tag_id).related.join(',')

    @acs = if ats.empty? 
      []
    else AcademicAllocation.find_by_sql <<-SQL
          SELECT ac.id, ac.academic_tool_type AS tool_type, ac.academic_tool_id AS tool_id, COALESCE(assignments.name, discussions.name, schedule_events.title, exams.name, chat_rooms.title, webconferences.title) AS name
          FROM academic_allocations ac
          LEFT JOIN assignments ON assignments.id = ac.academic_tool_id AND ac.academic_tool_type = 'Assignment'
          LEFT JOIN discussions ON discussions.id = ac.academic_tool_id AND ac.academic_tool_type = 'Discussion'
          LEFT JOIN webconferences ON webconferences.id = ac.academic_tool_id AND ac.academic_tool_type = 'Webconference'
          LEFT JOIN chat_rooms ON chat_rooms.id = ac.academic_tool_id AND ac.academic_tool_type = 'ChatRoom'
          LEFT JOIN schedule_events ON schedule_events.id = ac.academic_tool_id AND ac.academic_tool_type = 'ScheduleEvent'
          LEFT JOIN exams ON exams.id = ac.academic_tool_id AND ac.academic_tool_type = 'Exam'
          WHERE academic_tool_type IN (#{"'"+EvaluativeTool.descendants.join("','")+"'"})
          AND #{query}
          AND allocation_tag_id IN (#{ats})
          ORDER BY ac.academic_tool_type, assignments.name, discussions.name, schedule_events.title, exams.name, chat_rooms.title, webconferences.title;
      SQL
    end

    @tools = EvaluativeTool.descendants

    @users = Score.get_users(ats)
    @scores = Score.evaluative_frequency(ats, params[:type])

    render partial: 'evaluative_frequency', locals: {score_type: params[:type]}
  end

  def general
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @wh = AllocationTag.find(@allocation_tag_id).get_curriculum_unit.try(:working_hours)
    ats = AllocationTag.find(@allocation_tag_id).related.join(',')
    @users = AllocationTag.get_participants(@allocation_tag_id, { students: true }, true)
    @tools = ( ats.empty? ? [] : EvaluativeTool.count_tools(ats) )

    render partial: 'general'
  end

  def info
    authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = current_user

    @types = [ [t(:exam, scope: [:scores, :info]), 'exam'], [t(:assignments, scope: [:scores, :info]), 'assignment'],[t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat'],[t(:webconference, scope: [:scores, :info]), 'webconference'],[t(:schedule_events, scope: [:scores, :info]), 'schedule_event'], [t(:all, scope: [:scores, :info]), 'all']]

    @wh = Allocation.get_working_hours(@user.id, AllocationTag.find(@allocation_tag_id))

    @access, @public_files = Score.informations(@user.id, @allocation_tag_id)
  end

  def search_tool
    if params.include?(:user_id)
      begin
        authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
        @user = User.find(params[:user_id])
      rescue
        authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
        @user = current_user
      end
    else
      authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
      @user = current_user
    end
    
    tool = params[:tool][params[:tool].length.to_i-1]
    case tool
    when 'discussion'
      @can_evaluate = can? :evaluate, Discussion, { on: @allocation_tag_id }
      @discussions_evaluative     = Discussion.all_by_allocation_tags_evaluative(@allocation_tag_id, true)
      @discussions_frequency      = Discussion.all_by_allocation_tags_evaluative(@allocation_tag_id, false, true)
      @discussions_not_evaluative = Discussion.all_by_allocation_tags_evaluative(@allocation_tag_id)
      render partial: "scores/info/"+tool
    when 'chat'
      @can_evaluate = can? :evaluate, ChatRoom, { on: @allocation_tag_id }
      chats_evaluative = ChatRoom.list_chats(@user.id, @allocation_tag_id, true)
      chats_frequency = ChatRoom.list_chats(@user.id, @allocation_tag_id,false, true)
      chats_not_evaluative = ChatRoom.list_chats(@user.id, @allocation_tag_id)

      @chats_evaluative = chats_evaluative[:my]
      @chats_frequency = chats_frequency[:my]
      @chats_not_evaluative = chats_not_evaluative[:my]
      render partial: "scores/info/"+tool, locals: { chats: @my_chats, history: true, can_open_link: true }
    when 'webconference'  
      api = bbb_prepare
      @online = bbb_online?(api)
      @can_see_access = can? :evaluate, Webconference, { on: @allocation_tag_id }

      upper_ats = AllocationTag.find(@allocation_tag_id).related(upper: true)
     
      @webconferences_evaluative =  Webconference.all_by_allocation_tags(upper_ats, {asc: true}, (@can_see_access ? nil : @user.id), true, false)
      @webconferences_frequency = Webconference.all_by_allocation_tags(upper_ats, {asc: true}, (@can_see_access ? nil : @user.id), false, true)
      @webconferences_not_evaluative = Webconference.all_by_allocation_tags(upper_ats, {asc: true}, (@can_see_access ? nil : @user.id), true, true)
      render partial: "scores/info/"+tool
    when 'exam'
      @can_see_access = can? :evaluate, Exam, { on: @allocation_tag_id }

      @exams_evaluative = Exam.list_exams(@allocation_tag_id, true)
      @exams_frequency = Exam.list_exams(@allocation_tag_id, false, true)
      @exams_not_evaluative = Exam.list_exams(@allocation_tag_id)
      render partial: "scores/info/"+tool
    when 'assignment'
      @can_evaluate_ass = can? :evaluate, Assignment, { on: @allocation_tag_id }
      @assigments_evaluative = Assignment.list_assigment(@user.id, @allocation_tag_id, true) 
      @assigments_frequency = Assignment.list_assigment(@user.id, @allocation_tag_id, false, true) 
      @assigments_not_evaluative = Assignment.list_assigment(@user.id, @allocation_tag_id) 
      render partial: "scores/info/"+tool 
    when 'schedule_event'
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
    @wh = Allocation.get_working_hours(@user.id, AllocationTag.find(@allocation_tag_id))
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

  def redirect_to_evaluate
    tool_id = AcademicAllocation.find(params[:ac_id]).academic_tool_id

    if ['not_started', 'to_send'].include?(params[:situation])
      render json: { alert: t('scores.error.situation') }, status: :unprocessable_entity
    else
      case params[:tool_type]
      when 'Assignment'
        if params[:situation] == 'without_group'
          render json: { url: group_assignments_path(assignment_id: tool_id) }
        else
          render json: { url: student_assignment_path(tool_id, student_id: params[:user_id], group_id: params[:group_id]), method: :get }
        end
      when 'ChatRoom'
        render json: { url: user_messages_chat_room_path(tool_id, user_id: params[:user_id]) }
      when 'Webconference'
        render json: { url: list_access_webconference_path(tool_id, user_id: params[:user_id]) }
      when 'Discussion'
        render json: { url: user_discussion_posts_path(discussion_id: tool_id, user_id: params[:user_id]) }
      when 'ScheduleEvent'
        render json: { url: evaluate_user_schedule_event_path(tool_id, user_id: params[:user_id]) }
      when 'Exam'
        if params[:score_type] == 'frequency'
          render json: { url: result_user_exam_path(tool_id, user_id: params[:user_id])}
        else
          render json: { url: calcule_grade_exam_path(tool_id), method: :put }
        end
      end
    end

  end

end
