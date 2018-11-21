class ScoresController < ApplicationController

  include Bbb
  include SysLog::Actions

  before_filter :prepare_for_group_selection, only: :index
  before_filter :prepare_for_pagination, only: :index

  layout false, only: :search_tool

  require 'will_paginate/array'
  def index

    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @allocation_tag = AllocationTag.find(@allocation_tag_id)
    @allocation_tag.set_students_situations if @allocation_tag.can_set_situation_automatically?

    @group = @allocation_tag.groups.first
    @merged_group = @group.is_merged?

    ats = @allocation_tag.related
    @responsibles = AllocationTag.get_participants(@allocation_tag_id, { responsibles: true, profiles: Profile.with_access_on("create", "posts").join(",") }, true) if current_user.profiles_with_access_on("responsibles", "scores", ats).any?

    @users = AllocationTag.get_participants(@allocation_tag_id, { students: true }, true).paginate(page: params[:page], per_page: 20)
    @tools = ( ats.empty? ? [] : EvaluativeTool.count_tools(ats.join(',')) )
    @tools_list = EvaluativeTool.descendants

    @wh = @allocation_tag.get_curriculum_unit.try(:working_hours)
  end

  require 'will_paginate/array'
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

    @button_text_register_notes = @bloq_register_notes ? 'register_notes_on' : 'register_notes_off'

    @score_type = params[:type]
    if params[:report]
      @users = Score.get_users(ats)
      @ats = AllocationTag.find(@allocation_tag_id)
      @scores = Score.evaluative_frequency(ats, params[:type])

      @examidx          = params[:Examidx]          unless params[:Examidx].blank?
      @assignmentidx    = params[:Assignmentidx]    unless params[:Assignmentidx].blank?
      @scheduleEventidx = params[:ScheduleEventidx] unless params[:ScheduleEventidx].blank?
      @discussionidx    = params[:Discussionidx]    unless params[:Discussionidx].blank?
      @chatRoomidx      = params[:ChatRoomidx]      unless params[:ChatRoomidx].blank?
      @webconferenceidx = params[:Webconferenceidx] unless params[:Webconferenceidx].blank?

      send_data ReportsHelper.scores_evaluatives_frequency(@ats, @score_type, @users, @scores, @acs, @examidx, @assignmentidx, @scheduleEventidx, @discussionidx, @chatRoomidx, @webconferenceidx).render, :filename => "#{t("scores.reports.general_#{@score_type}")}.pdf", :type => "application/pdf", disposition: 'inline'

    else
      @users = Score.get_users(ats).paginate(page: params[:page], per_page: 20)
      @scores = Score.evaluative_frequency(ats, params[:type])

      @confirm = @scores.select { |s| s.situation == 'sent' }.count > 0 ? true : false
      score_open = @scores.select { |score| score.end_date > Date.today }.count > 0 ? true : false
      @score_open = score_open==true && @bloq_register_notes==false ? true : false
      
      respond_to do |format|
        format.html { render partial: 'evaluative_frequency', locals: {score_type: params[:type] }}
        format.json { render json: @users }
        format.js
      end
    end
  rescue => error
    request.format = :json
    raise error
  end

  require 'will_paginate/array'
  def general
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @wh = AllocationTag.find(@allocation_tag_id).get_curriculum_unit.try(:working_hours)
    ats = AllocationTag.find(@allocation_tag_id).related.join(',')
    @tools = ( ats.empty? ? [] : EvaluativeTool.count_tools(ats) )
    @allocation_tag = AllocationTag.find(@allocation_tag_id)

    @group = @allocation_tag.groups.first
    @merged_group = @group.is_merged?

    if params[:report]
      @users = AllocationTag.get_participants(@allocation_tag_id, { students: true }, true)
      @ats = AllocationTag.find(@allocation_tag_id)

      send_data ReportsHelper.scores_general(@ats, @wh, @users, @allocation_tag_id, @tools, params[:type], @merged_group).render, :filename => "#{t("scores.reports.#{params[:type]}")}.pdf", :type => "application/pdf", disposition: 'inline'

    else
      @users = AllocationTag.get_participants(@allocation_tag_id, { students: true }, true).paginate(:page => params[:page], :per_page => 20)
      respond_to do |format|
        format.html { render partial: "#{params[:type]}"  }
        format.json { render json: @users }
        format.js { render "#{params[:type]}.js.haml" }
      end
    end
  rescue => error
    request.format = :json
    raise error
  end

  def info
    authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = current_user

    @allocation_tag = AllocationTag.find(@allocation_tag_id)
    @curriculum_unit = @allocation_tag.get_curriculum_unit
    @responsible = AllocationTag.get_participants(@allocation_tag_id, {responsibles: true})

    group = @allocation_tag.groups.first
    @merged_group = group.is_merged?

    @is_student = @user.is_student?([@allocation_tag_id])
    @current_user_is_student = current_user.is_student?([@allocation_tag_id])

    if @is_student
      @types = [ [t(:exam, scope: [:scores, :info]), 'exam'], [t(:assignments, scope: [:scores, :info]), 'assignment'],[t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat_room'],[t(:webconference, scope: [:scores, :info]), 'webconference'],[t(:schedule_events, scope: [:scores, :info]), 'schedule_event'], [t(:all, scope: [:scores, :info]), 'all']]
    else
      @types = [ [t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat_room'],[t(:webconference, scope: [:scores, :info]), 'webconference']]
    end

    @access, @public_files, @access_count = Score.informations(@user.id, @allocation_tag_id)
  end

  def search_tool
    begin
      raise 'user' unless params.include?(:user_id)
      authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
      @user = User.find(params[:user_id])
    rescue
      authorize! :info, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
      @user = current_user
    end

    @is_student = @user.is_student?([@allocation_tag_id])
    @current_user_is_student = current_user.is_student?([@allocation_tag_id])

    case params[:tool]
    when 'discussion'
      @can_evaluate = can? :evaluate, Discussion, { on: @allocation_tag_id }
      @discussions_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'discussions', true)
      @discussions_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'discussions', false, true)
      @discussions_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'discussions')
    when 'chat_room'
      @can_evaluate = can? :evaluate, ChatRoom, { on: @allocation_tag_id }

      @chat_rooms_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'chat_rooms', true)
      @chat_rooms_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'chat_rooms', false, true)
      @chat_rooms_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'chat_rooms')
    when 'webconference'
      #@online = bbb_online?(bbb_prepare)
      @can_evaluate = can? :evaluate, Webconference, { on: @allocation_tag_id }
      @can_see_access = can? :list_access, Webconference, { on: @allocation_tag_id }

      @webconferences_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'webconferences', true)
      @webconferences_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'webconferences', false, true)
      @webconferences_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'webconferences')
    when 'exam'
      @can_see_access = can? :evaluate, Exam, { on: @allocation_tag_id }
      @can_open = can? :open, Exam, {on: @allocation_tag_id}

      @exams_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'exams', true)
      @exams_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'exams', false, true)
      @exams_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'exams')
    when 'assignment'
      @can_evaluate_ass = can? :evaluate, Assignment, { on: @allocation_tag_id }
      @assigments_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'assignments', true)
      @assigments_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'assignments', false, true)
      @assigments_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'assignments')
    when 'schedule_event'
      @can_evaluate = can? :evaluate, ScheduleEvent, { on: @allocation_tag_id }

      @schedules_event_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'schedule_events', true)
      @schedules_event_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'schedule_events', false, true)
      @schedules_event_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'schedule_events')
    else  #todos
      @can_evaluate = current_user.resources_by_allocation_tags_ids([@allocation_tag_id])
      @tool_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'all', true)
      @tool_frequency = Score.list_tool(@user.id, @allocation_tag_id, 'all', false, true)
      @tool_not_evaluative = Score.list_tool(@user.id, @allocation_tag_id, 'all')
    end
    @can_comment = (can? :create, Comment, { on: @allocation_tag_id } )

    render partial: "scores/info/"+params[:tool]
  end

  def reports_pdf
    allocation_tag_id = active_tab[:url][:allocation_tag_id]
    begin
      raise 'user' unless params.include?(:user_id)
      authorize! :index, Score, on: [allocation_tag_id]
      @user = User.find(params[:user_id])
    rescue
      authorize! :info, Score, on: [allocation_tag_id]
      @user = current_user
    end
    raise CanCan::AccessDenied unless @user.is_student?([allocation_tag_id])

    evaluative = params[:evaluative]
    frequency = params[:frequency]
    tool = params[:tool]
    if frequency
      @type = 'frequency'
    elsif evaluative
      @type = 'evaluative'
    elsif tool
      @type = 'all'
    else
      @type = 'not_evaluative'
    end

    at = AllocationTag.find(allocation_tag_id)
    @curriculum_unit = at.get_curriculum_unit

    @ats = AllocationTag.find(allocation_tag_id)
    @is_student = @user.is_student?([allocation_tag_id])
    @g = AcademicAllocationUser.get_grade_finish(@user.id, allocation_tag_id)

    @tool = Score.list_tool(@user.id, allocation_tag_id, 'all', evaluative, frequency, (@type == 'all'))
    @access, @public_files, @access_count = Score.informations(@user.id, allocation_tag_id)

    group = @ats.groups.first
    @merged_group = group.is_merged?

    send_data ReportsHelper.generate_pdf(@type, @ats, @user, @curriculum_unit, @is_student, @g, @tool, @access, @access_count, @public_files, @merged_group).render, :filename => "#{t("scores.reports.student_#{@type}", name: @user.name)}.pdf", :type => "application/pdf", disposition: 'inline'
  end

  def user_info
    authorize! :index, Score, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = User.find(params[:user_id])
    @access, @public_files, @access_count = Score.informations(@user.id, @allocation_tag_id)

    @allocation_tag = AllocationTag.find(@allocation_tag_id)
    @curriculum_unit = @allocation_tag.get_curriculum_unit
    @responsible = AllocationTag.get_participants(@allocation_tag_id, {responsibles: true})

    group = @allocation_tag.groups.first
    @merged_group = group.is_merged?

    @is_student = @user.is_student?([@allocation_tag_id])

    if @is_student
      @types = [ [t(:exam, scope: [:scores, :info]), 'exam'], [t(:assignments, scope: [:scores, :info]), 'assignment'],[t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat_room'],[t(:webconference, scope: [:scores, :info]), 'webconference'],[t(:schedule_events, scope: [:scores, :info]), 'schedule_event'], [t(:all, scope: [:scores, :info]), 'all']]
    else
      @types = [ [t(:discussions, scope: [:scores, :info]), 'discussion'], [t(:chat, scope: [:scores, :info]), 'chat_room'],[t(:webconference, scope: [:scores, :info]), 'webconference']]
    end

    render :info
  end

  def info_summary
    authorize! :index, Score, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    render partial: 'scores/info/summary', locals: {user: User.find(params[:user_id]), allocation_tag_id: allocation_tag_id}
  rescue => error
    render status: :unauthorized
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
          render json: { url: group_assignments_path(assignment_id: tool_id, score_type: params[:score_type]) }
        else
          render json: { url: summarized_assignment_path(tool_id, student_id: params[:user_id], group_id: params[:group_id], score_type: params[:score_type], situation: params[:situation]) }
        end
      when 'ChatRoom'
        render json: { url: user_messages_chat_room_path(tool_id, user_id: params[:user_id], score_type: params[:score_type], situation: params[:situation]) }
      when 'Webconference'
        render json: { url: user_access_webconference_path(tool_id, user_id: params[:user_id], score_type: params[:score_type], situation: params[:situation]) }
      when 'Discussion'
        render json: { url: user_discussion_posts_path(discussion_id: tool_id, user_id: params[:user_id], score_type: params[:score_type], situation: params[:situation]) }
      when 'ScheduleEvent'
        render json: { url: summarized_schedule_event_path(tool_id, user_id: params[:user_id], score_type: params[:score_type], situation: params[:situation], back_to_participants: params[:back_to_participants]) }
      when 'Exam'
        params[:score_type] = 'not_evaluative' if params[:score_type].blank?
        if ['evaluated', 'corrected'].include?(params[:situation])
          render json: { url: open_exam_path(tool_id, situation: params[:situation], user_id: params[:user_id]) }
        else
          render json: { url: calculate_grade_exam_path(tool_id, ac_id: params[:ac_id], user_id: params[:user_id], score_type: params[:score_type]), method: :put }
        end
      end
    end
  end

  def redirect_to_open
    tool_id = AcademicAllocation.find(params[:ac_id]).academic_tool_id

    unless ['started', 'opened', 'retake', 'to_answer', 'to_send', 'not_finished', 'sent', 'evaluated', 'to_be_sent', 'without_group', 'in_progress'].include?(params[:situation])
      if ((params[:situation] == 'not_started' or params[:situation] == 'corrected') && params[:tool_type] == 'Exam')
        authorize! :show, Question, { on: active_tab[:url][:allocation_tag_id] }
        render json: { url: preview_exam_path(tool_id, allocation_tags_ids: active_tab[:url][:allocation_tag_id]) }
      else
        render json: { alert: t('scores.error.situation2') }, status: :unprocessable_entity
      end
    else
      case params[:tool_type]
      when 'Assignment'
        if params[:situation] == 'without_group'
          render json: { url: group_assignments_path(assignment_id: tool_id, score_type: params[:score_type]) }
        else
          render json: { url: student_assignment_path(tool_id, student_id: params[:user_id], group_id: params[:group_id]), method: :get }
        end
      when 'ChatRoom'
        profiles = current_user.profiles_with_access_on(:show, 'chat_rooms', [active_tab[:url][:allocation_tag_id]].flatten, true)
        allocation = Allocation.where(profile_id: profiles, status: Allocation_Activated, user_id: current_user.id).first.try(:id)
        raise CanCan::AccessDenied if allocation.blank?
        render json: { url: access_chat_room_path(tool_id, academic_allocation_id: params[:ac_id], allocation_id: allocation) }
      when 'Webconference'
        authorize! :interact, Webconference, { on: active_tab[:url][:allocation_tag_id] }
        render json: { url: access_webconference_path(tool_id), method: :get, web: true }
      when 'Discussion'
        render json: { url: discussion_posts_path(discussion_id: tool_id), method: :get }
      when 'Exam'
        if can? :open, Exam, { on: active_tab[:url][:allocation_tag_id] }
          render json: { url:  pre_exam_path(tool_id, allocation_tag_id: @allocation_tag_id, situation: params[:situation]) }
        else
          authorize! :show, Question, { on: active_tab[:url][:allocation_tag_id] }
          render json: { url: preview_exam_path(tool_id, allocation_tags_ids: active_tab[:url][:allocation_tag_id]) }
        end
      end
    end
  rescue CanCan::AccessDenied
    render json: { alert: t(:no_permission) }, status: :unprocessable_entity
  rescue => error
    render json: { alert: t('scores.error.not_possible') }, status: :unprocessable_entity
  end

  def set_situation
    authorize! :set_situation, Score, { on: allocation_tag_id = active_tab[:url][:allocation_tag_id]}

    allocation_tag = AllocationTag.find(allocation_tag_id)
    raise 'date' if allocation_tag.situation_date.blank?
    allocation_tag.set_students_situations(true)

    render json: {success: true, notice: t('scores.notice.setted_situation')}
  rescue => error
    Rails.logger.info "[APP] [ERROR] [SET SITUATION SCORES] error: #{error}"
    render json: { alert: t('scores.error.not_possible_set_situation') }, status: :unprocessable_entity
  end

  def remove_situation
    authorize! :set_situation, Score, { on: allocation_tag_id = active_tab[:url][:allocation_tag_id]}

    allocation_tag = AllocationTag.find(allocation_tag_id)
    raise 'date' if allocation_tag.situation_date.blank? || allocation_tag.situation_date <= Date.today
    allocation_tag.remove_students_situations

    render json: {success: true, notice: t('scores.notice.removed_situation')}
  rescue => error
    Rails.logger.info "[APP] [ERROR] [SET SITUATION SCORES] error: #{error}"
    if error == 'date'
      render json: { alert: t('scores.error.not_possible_remove_situation') }, status: :unprocessable_entity
    else
      render json: { alert: t('scores.error.not_possible_remove_situation_date') }, status: :unprocessable_entity
    end
  end

  def set_register_notes
    authorize! :set_register_notes, Score, { on: allocation_tag_id = active_tab[:url][:allocation_tag_id]}

    allocation_tag = AllocationTag.find(allocation_tag_id)
    allocation_tag.bloq_register_notes = allocation_tag.bloq_register_notes==true ? false : true
    allocation_tag.save!
    button_text_register_notes= allocation_tag.bloq_register_notes == true ? 'register_notes_off' : 'register_notes_on'

    render json: {success: true, notice: t("scores.index.msg_#{button_text_register_notes}"), register_notes_text: t("scores.index.#{button_text_register_notes}")}
  rescue => error
    render json: { alert: t('scores.index.error_msg_register_notes') }, status: :unprocessable_entity
  end

end
