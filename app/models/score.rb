class Score # < ActiveRecord::Base

  
  def self.informations(user_id, at_id, related: nil)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)

    related = related || at.related

    history_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related).limit(5)
    public_files   = PublicFile.where(user_id: user_id, allocation_tag_id: at_id)
    count_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related).count
                        
    [history_access, public_files, count_access]
  end

  def self.list_tool(user_id, at_id, tool='all', evaluative=false, frequency=false, all=false, others=false, type=nil)
    evaluated_status = if frequency
      "WHEN academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    elsif !all
      "WHEN academic_allocation_users.grade IS NOT NULL THEN 'evaluated'"
    else 
      "WHEN academic_allocation_users.grade IS NOT NULL OR academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    end

    sent_status = if frequency || evaluative
      'academic_allocation_users.status = 1 OR (academic_allocation_users.status = 2 AND (academic_allocation_users.working_hours IS NOT NULL OR academic_allocation_users.grade IS NOT NULL))'
    else
      'academic_allocation_users.status = 1'
    end

    ats_ids = AllocationTag.find(at_id).related
    wq = "AND academic_allocations.evaluative=true " if evaluative
    wq = "AND academic_allocations.frequency=true "  if frequency
    wq = "AND academic_allocations.evaluative=false" if !evaluative && !frequency
    wq = '' if evaluative.blank? && frequency.blank? && all

    prepare_query = Score.get_query((tool == 'all' ? ['discussions','assignments','chat_rooms','webconferences','exams','schedule_events'] : [tool].flatten), ats_ids.join(','), user_id, wq, sent_status, evaluated_status, others, type)

    User.find_by_sql prepare_query
  end

  def self.evaluative_frequency(ats, type_score='evaluative')
    evaluated_status = if type_score == 'frequency'
      "WHEN academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    else
      "WHEN academic_allocation_users.grade IS NOT NULL THEN 'evaluated'"
    end

    sent_status = if type_score == 'frequency' || type_score == 'evaluative'
      'academic_allocation_users.status = 1 OR (academic_allocation_users.status = 2 AND (academic_allocation_users.working_hours IS NOT NULL OR academic_allocation_users.grade IS NOT NULL))'
    else
      'academic_allocation_users.status = 1'
    end

    wq = case type_score
         when 'evaluative'; "AND academic_allocations.evaluative=true "
         when 'frequency'; "AND academic_allocations.frequency=true "
         when 'not_evaluative'; "AND academic_allocations.evaluative=false "
         else
          ''
         end

  User.find_by_sql <<-SQL
    SELECT 
      academic_allocations.id, 
      academic_allocations.allocation_tag_id, 
      academic_allocations.academic_tool_id, 
      academic_allocations.academic_tool_type,  
      assignments.name,
      academic_allocation_users.grade,
      academic_allocation_users.working_hours AS wh,
      academic_allocation_users.new_after_evaluation,
      academic_allocation_users.status AS acu_status,
      users.id AS user_id, users.name AS user_name, users.active, gp.group_assignment_id AS group,
      CASE
        #{evaluated_status}
        WHEN assignments.id IS NOT NULL AND assignments.type_assignment = #{Assignment_Type_Group} AND gp.id IS NULL THEN 'without_group'
        WHEN (current_date < schedules.start_date AND (assignments.start_hour IS NULL OR assignments.start_hour = '')) OR (current_date = schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.start_hour != '' AND current_time<to_timestamp(assignments.start_hour, 'HH24:MI:SS')::time)) OR (current_date < schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.start_hour != '')) then 'not_started'
        WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Assignment' AND (af.id IS NOT NULL OR (aw.id IS NOT NULL))))) THEN 'sent'
        WHEN schedules.end_date >= current_date THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation     
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Assignment'
    JOIN assignments ON academic_allocations.academic_tool_id = assignments.id 
    JOIN schedules ON assignments.schedule_id = schedules.id
    LEFT JOIN group_assignments ga ON ga.academic_allocation_id = academic_allocations.id AND assignments.type_assignment = #{Assignment_Type_Group}
    LEFT JOIN group_participants gp ON gp.group_assignment_id = ga.id AND gp.user_id = users.id
    LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND (academic_allocation_users.user_id = users.id OR academic_allocation_users.group_assignment_id = gp.group_assignment_id)
    LEFT JOIN assignment_files af ON af.academic_allocation_user_id = academic_allocation_users.id
    LEFT JOIN assignment_webconferences aw ON aw.academic_allocation_user_id = academic_allocation_users.id
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) #{wq}

    UNION (
      SELECT 
      academic_allocations.id, 
      academic_allocations.allocation_tag_id, 
      academic_allocations.academic_tool_id, 
      academic_allocations.academic_tool_type, 
      chat_rooms.title,
      academic_allocation_users.grade,
      academic_allocation_users.working_hours AS wh,
      academic_allocation_users.new_after_evaluation,
      academic_allocation_users.status AS acu_status,
      users.id AS user_id, users.name AS user_name, users.active, NULL AS group,
      CASE
        #{evaluated_status}
        WHEN (#{sent_status} OR  academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'ChatRoom' AND chat_messages.id IS NOT NULL))) THEN 'sent'
        WHEN schedules.start_date > current_date OR (schedules.start_date = current_date AND current_time < to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time) THEN 'not_started'
        WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (chat_rooms.start_hour IS NULL OR current_time>to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time ) AND (chat_rooms.end_hour IS NULL OR current_time<=to_timestamp(chat_rooms.end_hour, 'HH24:MI:SS')::time) THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='ChatRoom'
    JOIN chat_rooms ON academic_allocations.academic_tool_id = chat_rooms.id 
    JOIN schedules ON chat_rooms.schedule_id = schedules.id
    LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
    LEFT JOIN chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id AND chat_messages.allocation_id = allocations.id AND message_type = 1
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) #{wq})

    UNION (
      SELECT 
      academic_allocations.id, 
      academic_allocations.allocation_tag_id, 
      academic_allocations.academic_tool_id, 
      academic_allocations.academic_tool_type, 
      discussions.name,
      academic_allocation_users.grade,
      academic_allocation_users.working_hours AS wh,
      academic_allocation_users.new_after_evaluation,
      academic_allocation_users.status AS acu_status,
      users.id AS user_id, users.name AS user_name, users.active, NULL AS group,
      CASE
        #{evaluated_status}
        WHEN (#{sent_status} OR academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Discussion' AND discussion_posts.id IS NOT NULL))) THEN 'sent'
        WHEN schedules.start_date > current_date THEN 'not_started'
        WHEN schedules.start_date <= current_date AND schedules.end_date >= current_date THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Discussion'
    JOIN discussions ON academic_allocations.academic_tool_id = discussions.id 
    JOIN schedules ON discussions.schedule_id = schedules.id
    LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
    LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id AND discussion_posts.user_id = users.id
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) #{wq})
    
    UNION
    (SELECT 
      academic_allocations.id, 
      academic_allocations.allocation_tag_id, 
      academic_allocations.academic_tool_id, 
      academic_allocations.academic_tool_type, 
      exams.name,
      academic_allocation_users.grade,
      academic_allocation_users.working_hours AS wh,
      academic_allocation_users.new_after_evaluation,
      academic_allocation_users.status AS acu_status,
      users.id AS user_id, users.name AS user_name, users.active, NULL AS group,
      CASE
        #{evaluated_status}
        WHEN #{sent_status} THEN 'sent'
        WHEN (current_date < s.start_date) OR  (current_date = s.start_date AND (exams.start_hour IS NOT NULL AND exams.end_hour != '' AND current_time<to_timestamp(exams.start_hour, 'HH24:MI:SS')::time)) THEN 'not_started'
        WHEN ((current_date >= s.start_date AND (exams.start_hour IS NULL OR exams.start_hour = '' OR current_time>= to_timestamp(exams.start_hour, 'HH24:MI:SS')::time) AND current_date <= s.end_date AND (exams.end_hour IS NULL OR exams.end_hour = '' OR current_time<=to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Exam'
    JOIN exams ON academic_allocations.academic_tool_id = exams.id
    JOIN schedules s ON exams.schedule_id = s.id
     LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND exams.status = 't' #{wq})
  
    UNION
    (SELECT 
      academic_allocations.id, 
      academic_allocations.allocation_tag_id, 
      academic_allocations.academic_tool_id, 
      academic_allocations.academic_tool_type, 
      schedule_events.title,
      academic_allocation_users.grade,
      academic_allocation_users.working_hours AS wh,
      academic_allocation_users.new_after_evaluation,
      academic_allocation_users.status AS acu_status,
      users.id AS user_id, users.name AS user_name, users.active, NULL AS group,
      CASE
        #{evaluated_status}
        WHEN #{sent_status} THEN 'sent'
        WHEN current_date<schedules.start_date OR (current_date = schedules.start_date AND current_time<to_timestamp(start_hour, 'HH24:MI:SS')::time)  THEN 'not_started'
        WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND (start_hour IS NULL OR current_time>=to_timestamp(start_hour, 'HH24:MI:SS')::time AND current_time<=to_timestamp(end_hour, 'HH24:MI:SS')::time) THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='ScheduleEvent'
    JOIN schedule_events ON academic_allocations.academic_tool_id = schedule_events.id 
    JOIN schedules ON schedule_events.schedule_id = schedules.id
    LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) #{wq})

  UNION
    (SELECT 
      academic_allocations.id, 
      academic_allocations.allocation_tag_id, 
      academic_allocations.academic_tool_id, 
      academic_allocations.academic_tool_type, 
      webconferences.title,
      academic_allocation_users.grade,
      academic_allocation_users.working_hours AS wh,
      academic_allocation_users.new_after_evaluation,
      academic_allocation_users.status AS acu_status,
      users.id AS user_id, users.name AS user_name, users.active, NULL AS group,
      CASE
        #{evaluated_status}
        WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Webconference' AND log_actions.id IS NOT NULL))) THEN 'sent'
        WHEN webconferences.initial_time > now() THEN 'not_started'
        WHEN webconferences.initial_time + (interval '1 min')*webconferences.duration > now() THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Webconference'
    JOIN webconferences ON academic_allocations.academic_tool_id = webconferences.id 
    LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
    LEFT JOIN log_actions ON academic_allocations.id = log_actions.academic_allocation_id AND log_actions.log_type = 7 AND log_actions.user_id = users.id
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) #{wq})
    
    ORDER BY acu_status, situation, academic_tool_type;
    SQL
    
  end


  def self.evaluative_frequency_situation(ats, user_id, group_id, tool_id, tool_type, type_score='evaluative')
    evaluated_status = if type_score == 'frequency'
      "WHEN academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    else
      "WHEN academic_allocation_users.grade IS NOT NULL THEN 'evaluated'"
    end

    sent_status = if type_score == 'frequency' || type_score == 'evaluative'
      'academic_allocation_users.status = 1 OR (academic_allocation_users.status = 2 AND (academic_allocation_users.working_hours IS NOT NULL OR academic_allocation_users.grade IS NOT NULL))'
    else
      'academic_allocation_users.status = 1'
    end

    wq = case type_score
         when 'evaluative'; "AND academic_allocations.evaluative=true "
         when 'frequency'; "AND academic_allocations.frequency=true "
         when 'not_evaluative'; "AND academic_allocations.evaluative=false "
         else
          ''
         end

    case tool_type
      when 'assignment'
        user = (group_id.blank? ? "users.id = #{user_id}" : "ga.id = #{group_id}")
        acu = (group_id.blank? ? "academic_allocation_users.user_id = #{user_id}" : "academic_allocation_users.group_assignment_id = #{group_id}")
        User.find_by_sql <<-SQL
          SELECT 
            CASE
              #{evaluated_status}
              WHEN assignments.id IS NOT NULL AND assignments.type_assignment = #{Assignment_Type_Group} AND ga.id IS NULL THEN 'without_group'
              WHEN (current_date < schedules.start_date AND (assignments.start_hour IS NULL OR assignments.start_hour = '')) OR (current_date = schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.start_hour != '' AND current_time<to_timestamp(assignments.start_hour, 'HH24:MI:SS')::time)) OR (current_date < schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.start_hour != '')) then 'not_started'
              WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Assignment' AND (af.id IS NOT NULL OR (aw.id IS NOT NULL))))) THEN 'sent'
              WHEN schedules.end_date >= current_date THEN 'to_send'
              ELSE 
                'not_sent'
              END AS situation     
          FROM users
          JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Assignment'
          JOIN assignments ON academic_allocations.academic_tool_id = assignments.id 
          JOIN schedules ON assignments.schedule_id = schedules.id
          LEFT JOIN group_assignments ga ON ga.academic_allocation_id = academic_allocations.id AND assignments.type_assignment = #{Assignment_Type_Group}
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND #{acu}
          LEFT JOIN assignment_files af ON af.academic_allocation_user_id = academic_allocation_users.id
          LEFT JOIN assignment_webconferences aw ON aw.academic_allocation_user_id = academic_allocation_users.id
          WHERE #{user} AND academic_allocations.academic_tool_id=#{tool_id} #{wq} 
        SQL
      when 'chatroom'     
        User.find_by_sql <<-SQL   
          SELECT 
          CASE
            #{evaluated_status}
            WHEN (#{sent_status} OR  academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'ChatRoom' AND chat_messages.id IS NOT NULL))) THEN 'sent'
            WHEN schedules.start_date > current_date OR (schedules.start_date = current_date AND current_time < to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time) THEN 'not_started'
            WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (chat_rooms.start_hour IS NULL OR current_time>to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time ) AND (chat_rooms.end_hour IS NULL OR current_time<=to_timestamp(chat_rooms.end_hour, 'HH24:MI:SS')::time) THEN 'to_send'
            ELSE 
              'not_sent'
            END AS situation
          FROM users
          JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
          JOIN profiles ON allocations.profile_id = profiles.id
          JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='ChatRoom'
          JOIN chat_rooms ON academic_allocations.academic_tool_id = chat_rooms.id 
          JOIN schedules ON chat_rooms.schedule_id = schedules.id
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
          LEFT JOIN chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id AND chat_messages.allocation_id = allocations.id AND message_type = 1
          WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND users.id=#{user_id} AND academic_allocations.academic_tool_id=#{tool_id} #{wq}
        SQL
      when 'discussion'     
        User.find_by_sql <<-SQL   
          SELECT 
          CASE
              #{evaluated_status}
              WHEN (#{sent_status} OR academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Discussion' AND discussion_posts.id IS NOT NULL))) THEN 'sent'
              WHEN schedules.start_date > current_date THEN 'not_started'
              WHEN schedules.start_date <= current_date AND schedules.end_date >= current_date THEN 'to_send'
              ELSE 
                'not_sent'
              END AS situation
          FROM users
          JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
          JOIN profiles ON allocations.profile_id = profiles.id
          JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Discussion'
          JOIN discussions ON academic_allocations.academic_tool_id = discussions.id 
          JOIN schedules ON discussions.schedule_id = schedules.id
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
          LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id AND discussion_posts.user_id = users.id
          WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND users.id=#{user_id} AND academic_allocations.academic_tool_id=#{tool_id} #{wq}
        SQL

      when 'exam'     
        User.find_by_sql <<-SQL   
          SELECT 
          CASE
              #{evaluated_status}
              WHEN #{sent_status} THEN 'sent'
              WHEN (current_date < s.start_date AND (exams.start_hour IS NULL OR exams.start_hour = '')) OR  (current_date <= s.start_date AND (exams.start_hour IS NOT NULL AND exams.end_hour != '' AND current_time<to_timestamp(exams.start_hour, 'HH24:MI:SS')::time)) THEN 'not_started'
              WHEN ((current_date >= s.start_date AND (exams.start_hour IS NULL OR exams.start_hour = '' OR current_time>= to_timestamp(exams.start_hour, 'HH24:MI:SS')::time) AND current_date <= s.end_date AND (exams.end_hour IS NULL OR exams.end_hour = '' OR current_time<=to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) THEN 'to_send'
              ELSE 
                'not_sent'
              END AS situation
          FROM users
          JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
          JOIN profiles ON allocations.profile_id = profiles.id
          JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Exam'
          JOIN exams ON academic_allocations.academic_tool_id = exams.id
          JOIN schedules s ON exams.schedule_id = s.id
           LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
          WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND exams.status = 't' AND users.id=#{user_id} AND academic_allocations.academic_tool_id=#{tool_id} #{wq}
        SQL
      when 'scheduleevent'     
        User.find_by_sql <<-SQL   
          SELECT 
          CASE
              #{evaluated_status}
              WHEN #{sent_status} THEN 'sent'
              WHEN current_date<schedules.start_date OR (current_date = schedules.start_date AND current_time<to_timestamp(start_hour, 'HH24:MI:SS')::time)  THEN 'not_started'
              WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND (start_hour IS NULL OR current_time>=to_timestamp(start_hour, 'HH24:MI:SS')::time AND current_time<=to_timestamp(end_hour, 'HH24:MI:SS')::time) THEN 'to_send'
              ELSE 
                'not_sent'
              END AS situation
          FROM users
          JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
          JOIN profiles ON allocations.profile_id = profiles.id
          JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='ScheduleEvent'
          JOIN schedule_events ON academic_allocations.academic_tool_id = schedule_events.id 
          JOIN schedules ON schedule_events.schedule_id = schedules.id
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
          WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND users.id=#{user_id} AND academic_allocations.academic_tool_id=#{tool_id} #{wq}
        SQL
      when 'webconference'     
        User.find_by_sql <<-SQL   
          SELECT 
              CASE
            #{evaluated_status}
            WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Webconference' AND log_actions.id IS NOT NULL))) THEN 'sent'
            WHEN webconferences.initial_time > now() THEN 'not_started'
            WHEN webconferences.initial_time + (interval '1 min')*webconferences.duration > now() THEN 'to_send'
            ELSE 
              'not_sent'
            END AS situation
          FROM users
          JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
          JOIN profiles ON allocations.profile_id = profiles.id
          JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Webconference'
          JOIN webconferences ON academic_allocations.academic_tool_id = webconferences.id 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
          LEFT JOIN log_actions ON academic_allocations.id = log_actions.academic_allocation_id AND log_actions.log_type = 7 AND log_actions.user_id = users.id
          WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND users.id=#{user_id} AND academic_allocations.academic_tool_id=#{tool_id} #{wq}
      SQL
    end
  end


  def self.get_users(ats)
    User.find_by_sql <<-SQL
      SELECT DISTINCT users.id, users.name
      FROM users
      JOIN allocations ON allocations.user_id = users.id
      JOIN profiles ON profiles.id = allocations.profile_id
      WHERE allocations.allocation_tag_id IN (#{ats})
      AND cast( profiles.types & '#{Profile_Type_Student}' as boolean )
      AND allocations.status = #{Allocation_Activated}
      ORDER BY name;
    SQL
  end

  private

    def self.get_query(tools, ats, user_id, wq, sent_status='', evaluated_status='', others=false, type=nil)
      ats_query = ats.blank? ? '' : "AND academic_allocations.allocation_tag_id IN (#{ats})"
      
      query = []

      tools.each do |tool|
        query << case tool
        when 'discussions'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type,
            academic_allocations.max_working_hours,
            academic_allocations.final_exam,
            discussions.name AS name,
            discussions.description,
            s.start_date,
            s.end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            eq_disc.name AS eq_name,
            NULL AS group_id,
            NULL AS type_tool,
            '' AS start_hour,
            '' AS end_hour,
            (SELECT COUNT(id) FROM discussion_posts WHERE discussion_posts.academic_allocation_id = academic_allocations.id AND user_id = #{user_id})::text AS count,
            (SELECT COUNT(id) FROM discussion_posts WHERE discussion_posts.academic_allocation_id = academic_allocations.id ) AS count_all,
            NULL as moderator,
            NULL as duration,
            NULL as server,
            CASE 
              WHEN s.start_date <= current_date AND s.end_date >= current_date THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN s.end_date < current_date THEN true
              ELSE 
                false
              END AS closed,
            CASE
             #{evaluated_status}
             WHEN (#{sent_status} OR academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Discussion' AND discussion_posts.id IS NOT NULL))) THEN 'sent'
             WHEN s.start_date > current_date THEN 'not_started'
             WHEN s.start_date <= current_date AND s.end_date >= current_date THEN 'opened'
             WHEN s.end_date < current_date THEN 'closed'
            END AS situation,
            academic_allocations.evaluative,
            academic_allocations.frequency
          FROM discussions, schedules s, academic_allocations 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
          LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id AND discussion_posts.user_id = #{user_id}
          LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id
          LEFT JOIN discussions eq_disc ON eq_disc.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'Discussion'
          WHERE 
            academic_allocations.academic_tool_id = discussions.id AND academic_allocations.academic_tool_type='Discussion' AND discussions.schedule_id=s.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats})
          )"

        when 'assignments'
          type =  if type.blank?
                    ''
                  else
                    "AND assignments.type_assignment = #{type}"
                  end

          "(
             WITH groups AS ( 
                SELECT group_participants.group_assignment_id AS group_id , ac.id AS ac_id
                FROM group_participants 
                JOIN group_assignments ON group_assignments.id = group_participants.group_assignment_id
                JOIN academic_allocations ac ON ac.allocation_tag_id IN (#{ats}) AND ac.academic_tool_type = 'Assignment' AND ac.id = group_assignments.academic_allocation_id
                WHERE user_id = #{user_id}
              )
              SELECT DISTINCT 
                academic_allocations.id, 
                academic_allocations.allocation_tag_id, 
                academic_allocations.academic_tool_id, 
                academic_allocations.academic_tool_type,
                academic_allocations.max_working_hours,
                academic_allocations.final_exam,
                assignments.name AS name,
                assignments.enunciation AS description,
                schedules.start_date,
                schedules.end_date,
                academic_allocation_users.grade,
                academic_allocation_users.working_hours,
                academic_allocation_users.user_id,
                academic_allocation_users.new_after_evaluation,
                eq_assig.name AS eq_name,
                groups.group_id::text AS group_id,
                assignments.type_assignment::text as type_tool,
                assignments.start_hour AS start_hour,
                assignments.end_hour AS end_hour,
                ((select count(assignment_files.id) FROM assignment_files WHERE assignment_files.academic_allocation_user_id = academic_allocation_users.id) + (select count(assignment_webconferences.id) FROM assignment_webconferences WHERE assignment_webconferences.academic_allocation_user_id = academic_allocation_users.id))::text AS count,
                (select count(assignment_comments.id) FROM assignment_comments WHERE assignment_comments.academic_allocation_user_id = academic_allocation_users.id) AS count_all,
                NULL as moderator,
                NULL as duration,
                NULL as server,
                CASE 
                  WHEN schedules.start_date <= current_date AND schedules.end_date >= current_date THEN true
                  ELSE 
                    false
                  END AS opened,
                CASE 
                  WHEN schedules.end_date < current_date THEN true
                  ELSE 
                    false
                  END AS closed,
                case
                  #{evaluated_status}
                  when assignments.type_assignment = #{Assignment_Type_Group} AND groups.group_id IS NULL  then 'without_group'
                  when (current_date < schedules.start_date AND (assignments.start_hour IS NULL OR assignments.start_hour = '')) OR (current_date = schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.start_hour != '' AND current_time<to_timestamp(assignments.start_hour, 'HH24:MI:SS')::time)) OR (current_date < schedules.start_date AND (assignments.start_hour IS NOT NULL AND assignments.start_hour != '')) then 'not_started'
                  when #{sent_status} OR academic_allocation_users.status = 1 OR attachment_updated_at IS NOT NULL OR (assignment_webconferences.id IS NOT NULL AND is_recorded AND (initial_time + (interval '1 mins')*duration) < now()) then 'sent'
                  when (current_date <= schedules.end_date AND current_date >= schedules.start_date AND (assignments.end_hour IS NULL OR assignments.end_hour = '' AND assignments.start_hour IS NULL OR assignments.start_hour = '')) OR (current_date <= schedules.end_date AND current_date >= schedules.start_date AND (assignments.end_hour IS NOT NULL AND assignments.end_hour != '' AND current_time<=to_timestamp(assignments.end_hour, 'HH24:MI:SS')::time)) then 'to_be_sent'
                  else  'not_sent'
                 end AS situation,
                 academic_allocations.evaluative,
                 academic_allocations.frequency
              FROM assignments, schedules, academic_allocations 
              LEFT JOIN (select group_id, ac_id from groups) AS groups ON groups.ac_id = academic_allocations.id
              LEFT JOIN academic_allocation_users ON academic_allocations.id = academic_allocation_users.academic_allocation_id AND (academic_allocation_users.user_id = #{user_id} OR (academic_allocation_users.group_assignment_id = groups.group_id))
              LEFT JOIN assignment_files ON assignment_files.academic_allocation_user_id = academic_allocation_users.id
              LEFT JOIN assignment_webconferences ON assignment_webconferences.academic_allocation_user_id = academic_allocation_users.id
              LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id
              LEFT JOIN assignments eq_assig ON eq_assig.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'Assignment'
              WHERE 
                academic_allocations.academic_tool_id = assignments.id AND academic_allocations.academic_tool_type='Assignment' AND assignments.schedule_id=schedules.id #{wq} #{type} AND academic_allocations.allocation_tag_id IN (#{ats}) AND 
                (academic_allocation_users.id IS NULL OR (academic_allocation_users.user_id = #{user_id} OR (academic_allocation_users.group_assignment_id = groups.group_id AND assignments.type_assignment = #{Assignment_Type_Group}) OR (groups.group_id IS NULL AND assignments.type_assignment = #{Assignment_Type_Group})) OR (academic_allocation_users.user_id IS NULL AND academic_allocation_users.group_assignment_id IS NULL))
                GROUP BY academic_allocations.id, academic_allocations.allocation_tag_id, academic_allocations.academic_tool_id, academic_allocations.academic_tool_type, assignments.name,  schedules.start_date,  schedules.end_date, assignments.enunciation, new_after_evaluation, academic_allocation_users.grade,  academic_allocation_users.working_hours, academic_allocation_users.user_id, assignments.start_hour, assignments.end_hour, academic_allocations.evaluative, academic_allocations.frequency, eq_assig.name, groups.group_id, assignments.type_assignment, academic_allocation_users.id, assignment_webconferences.id, assignment_files.attachment_updated_at
          )"
        when 'chat_rooms'
          others =  if others
                      "((chat_rooms.chat_type = 1 AND chat_participants.id IS NULL) OR cast(profiles.types & #{Profile_Type_Observer} as boolean)"
                    else
                      "((cast(profiles.types & #{Profile_Type_Student} as boolean) AND (chat_rooms.chat_type = 0 OR chat_participants.id IS NOT NULL)) OR cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)"
                    end
          "( SELECT DISTINCT
              academic_allocations.id, 
              academic_allocations.allocation_tag_id, 
              academic_allocations.academic_tool_id, 
              academic_allocations.academic_tool_type,
              academic_allocations.max_working_hours,
              academic_allocations.final_exam,
              chat_rooms.title AS name,
              chat_rooms.description,
              schedules.start_date,
              schedules.end_date,
              academic_allocation_users.grade,
              academic_allocation_users.working_hours,
              academic_allocation_users.user_id,
              academic_allocation_users.new_after_evaluation,
              eq_chat.title AS eq_name,
              NULL AS group_id,
              chat_rooms.chat_type::text AS type_tool,
              chat_rooms.start_hour,
              chat_rooms.end_hour,
              COALESCE(chat_messages.count, 0)::text as count,
              0 as count_all,
              NULL as moderator,
              NULL as duration,
              NULL as server,
              CASE 
              WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (chat_rooms.start_hour IS NULL OR current_time>to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time ) AND (chat_rooms.end_hour IS NULL OR current_time<=to_timestamp(chat_rooms.end_hour, 'HH24:MI:SS')::time) THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN (current_date > schedules.end_date) OR (current_date = schedules.end_date AND (chat_rooms.end_hour IS NULL OR current_time>to_timestamp(chat_rooms.end_hour, 'HH24:MI:SS')::time)) THEN true
              ELSE 
                false
              END AS closed,
              CASE 
                #{evaluated_status}   
                WHEN (#{sent_status} OR  academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'ChatRoom' AND chat_messages.count > 0))) THEN 'sent'
                WHEN schedules.start_date > current_date OR (schedules.start_date = current_date AND current_time < to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time) THEN 'not_started'
                WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (chat_rooms.start_hour IS NULL OR current_time>to_timestamp(chat_rooms.start_hour, 'HH24:MI:SS')::time ) AND (chat_rooms.end_hour IS NULL OR current_time<=to_timestamp(chat_rooms.end_hour, 'HH24:MI:SS')::time) THEN 'opened'
                ELSE
                'closed'
              END AS situation,
            academic_allocations.evaluative,
            academic_allocations.frequency
            FROM chat_rooms, schedules, academic_allocations 
            LEFT JOIN allocations ON allocations.user_id = #{user_id} AND allocations.allocation_tag_id IN (#{ats})
            LEFT JOIN profiles ON profiles.id = allocations.profile_id
            LEFT JOIN(
              SELECT COUNT(chat_messages.id), chat_messages.academic_allocation_id
              FROM chat_messages
              LEFT JOIN allocations ON allocations.user_id = #{user_id} AND allocations.allocation_tag_id IN (#{ats})
              WHERE message_type = 1 AND chat_messages.allocation_id = allocations.id
              GROUP BY chat_messages.academic_allocation_id
            ) chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id
            LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
            LEFT JOIN chat_participants ON chat_participants.academic_allocation_id = academic_allocations.id AND chat_participants.allocation_id = allocations.id
            LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id
            LEFT JOIN chat_rooms eq_chat ON eq_chat.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'ChatRoom'
            WHERE 
              academic_allocations.academic_tool_id = chat_rooms.id AND academic_allocations.academic_tool_type='ChatRoom' AND chat_rooms.schedule_id=schedules.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats}) AND (#{others} ))
            )"

        when 'exams'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type,
            academic_allocations.max_working_hours,
            academic_allocations.final_exam,
            exams.name AS name,
            exams.description,
            s.start_date,
            s.end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            eq_exam.name AS eq_name,
            NULL AS group_id,
            NULL AS type_tool,
            exams.start_hour,
            exams.end_hour,
            NULL as count,
            0 as count_all,
            NULL as moderator,
            exams.duration::text,
            NULL as server,
            CASE 
              WHEN (current_date >= s.start_date AND current_date <= s.end_date) AND (exams.start_hour IS NULL OR exams.start_hour = '' OR current_time > to_timestamp(exams.start_hour, 'HH24:MI:SS')::time) AND (exams.end_hour IS NULL OR exams.end_hour = '' OR current_time < to_timestamp(exams.end_hour, 'HH24:MI:SS')::time) THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN (current_date > s.end_date) OR (current_date = s.end_date AND exams.end_hour IS NOT NULL AND exams.end_hour != '' AND current_time > to_timestamp(exams.end_hour, 'HH24:MI:SS')::time) THEN true
              ELSE 
                false
              END AS closed,
            case
            when (current_date < s.start_date) OR (current_date = s.start_date AND ((exams.start_hour IS NOT NULL AND exams.end_hour != '' AND current_time<to_timestamp(exams.start_hour, 'HH24:MI:SS')::time))) then 'not_started'
            when ((current_date >= s.start_date AND (exams.start_hour IS NULL OR exams.start_hour = '' OR current_time>= to_timestamp(exams.start_hour, 'HH24:MI:SS')::time) AND current_date <= s.end_date AND (exams.end_hour IS NULL OR exams.end_hour = '' OR current_time<=to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) AND exam_responses.id IS NULL then 'to_answer'
            when ((current_date >= s.start_date AND (exams.start_hour IS NULL OR exams.start_hour = '' OR current_time>= to_timestamp(exams.start_hour, 'HH24:MI:SS')::time) AND current_date <= s.end_date AND (exams.end_hour IS NULL OR exams.end_hour = '' OR current_time<=to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) AND (exams.uninterrupted!=TRUE AND last_attempt.complete!=TRUE) then 'not_finished'
            when ((current_date >= s.start_date AND (exams.start_hour IS NULL OR exams.start_hour = '' OR current_time>= to_timestamp(exams.start_hour, 'HH24:MI:SS')::time) AND current_date <= s.end_date AND (exams.end_hour IS NULL OR exams.end_hour = '' OR current_time<=to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) AND user_attempts.count < exams.attempts then 'retake'
            when academic_allocation_users.grade IS NOT NULL AND (current_date > s.end_date OR  (current_date = s.end_date AND (exams.end_hour IS NOT NULL AND exams.end_hour != '' AND current_time>to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) then 'corrected'
            when (current_date > s.end_date OR  (current_date = s.end_date AND (exams.end_hour IS NOT NULL AND exams.end_hour != '' AND current_time>to_timestamp(exams.end_hour, 'HH24:MI:SS')::time))) AND (user_attempts.count > 0 ) AND academic_allocation_users.grade IS NULL then 'not_corrected'
            when (last_attempt.complete=TRUE OR exams.uninterrupted=TRUE) AND (exams.attempts = user_attempts.count) then 'finished'
            else
              'not_answered'
            end AS situation,
            academic_allocations.evaluative,
            academic_allocations.frequency
          FROM exams, schedules s, academic_allocations 
            LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
            LEFT JOIN exam_user_attempts ON exam_user_attempts.academic_allocation_user_id = academic_allocation_users.id
            LEFT JOIN exam_user_attempts last_attempt ON last_attempt.updated_at = (SELECT MAX(updated_at)
                                                                                    FROM exam_user_attempts
                                                                                    GROUP BY academic_allocation_user_id
                                                                                    HAVING academic_allocation_user_id = academic_allocation_users.id)
            LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id 
            LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id
            LEFT JOIN exams eq_exam ON eq_exam.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'Exam'
            LEFT JOIN ( (SELECT COUNT(exam_user_attempts.id), acu.academic_allocation_id AS ac_id FROM exam_user_attempts LEFT JOIN academic_allocation_users acu ON exam_user_attempts.academic_allocation_user_id = acu.id WHERE acu.user_id = #{user_id} GROUP BY acu.academic_allocation_id)) user_attempts ON user_attempts.ac_id = academic_allocations.id
          WHERE 
            academic_allocations.academic_tool_id = exams.id AND academic_allocations.academic_tool_type='Exam' AND exams.schedule_id=s.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats}) AND exams.status = 't'
            GROUP BY academic_allocations.id, academic_allocations.allocation_tag_id, academic_allocations.academic_tool_id, academic_allocations.academic_tool_type, exams.name,  s.start_date,  s.end_date, exams.description, new_after_evaluation, academic_allocation_users.grade,  academic_allocation_users.working_hours, academic_allocation_users.user_id, exams.start_hour, exams.end_hour, exam_responses.id, exams.attempts, eq_exam.name, exams.duration, academic_allocations.evaluative, academic_allocations.frequency, user_attempts.count, last_attempt.complete, exams.uninterrupted
          ) "

        when 'schedule_events'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type,
            academic_allocations.max_working_hours,
            academic_allocations.final_exam,
            schedule_events.title AS name,
            schedule_events.description,
            schedules.start_date,
            schedules.end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            eq_event.title AS eq_name,
            NULL AS group_id,
            NULL AS type_tool,
            schedule_events.start_hour,
            schedule_events.end_hour,
            NULL as count,
            0 as count_all,
            NULL as moderator,
            NULL as duration,
            NULL as server,
            CASE 
              WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (schedule_events.start_hour IS NULL OR current_time > to_timestamp(schedule_events.start_hour, 'HH24:MI:SS')::time) AND (schedule_events.end_hour IS NULL OR current_time<=to_timestamp(schedule_events.end_hour, 'HH24:MI:SS')::time) THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN (current_date > schedules.end_date) AND (schedule_events.end_hour IS NULL OR current_time>to_timestamp(schedule_events.start_hour, 'HH24:MI:SS')::time) THEN true
              ELSE 
                false
              END AS closed,
            CASE
            #{evaluated_status}
            WHEN current_date>schedules.end_date OR current_date=schedules.end_date AND current_time>to_timestamp(schedule_events.end_hour, 'HH24:MI:SS')::time THEN 'closed'
            WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND schedule_events.start_hour IS NULL THEN 'started'
            WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND current_time>=to_timestamp(schedule_events.start_hour, 'HH24:MI:SS')::time AND current_time<=to_timestamp(schedule_events.end_hour, 'HH24:MI:SS')::time THEN 'started'
            ELSE 'not_started'  
            END AS situation,
            academic_allocations.evaluative,
            academic_allocations.frequency
          FROM schedule_events, schedules, academic_allocations 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
          LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id
          LEFT JOIN schedule_events eq_event ON eq_event.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'ScheduleEvent'
          WHERE 
            academic_allocations.academic_tool_id = schedule_events.id AND academic_allocations.academic_tool_type='ScheduleEvent' AND schedule_events.schedule_id=schedules.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats})
          )"

        when 'webconferences'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type, 
            academic_allocations.max_working_hours,
            academic_allocations.final_exam,
            webconferences.title AS name,
            webconferences.description,
            webconferences.initial_time AS start_date,
            webconferences.initial_time AS end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            eq_web.title AS eq_name,
            NULL AS group_id,
            webconferences.shared_between_groups::text AS type_tool,
            webconferences.initial_time || '' AS start_hour,
            webconferences.initial_time + webconferences.duration* interval '1 min' || '' AS end_hour,
            (SELECT COUNT(log_actions.id) FROM log_actions WHERE log_actions.academic_allocation_id = academic_allocations.id AND log_actions.user_id = #{user_id})::text as count,
            0 as count_all,
            webconferences.user_id::text as moderator,
            webconferences.duration::text,
            webconferences.server::text as server,
            CASE 
              when NOW()>webconferences.initial_time AND NOW()<=(webconferences.initial_time + webconferences.duration* interval '1 min') then true
              ELSE 
                false
              END AS opened,
            CASE 
              when NOW()>(webconferences.initial_time + webconferences.duration* interval '1 min') then true
              ELSE 
                false
              END AS closed,
            CASE
              #{evaluated_status}
              WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Webconference' AND log_actions.id IS NOT NULL))) THEN 'sent'
              when NOW()>webconferences.initial_time AND NOW()<(webconferences.initial_time + webconferences.duration* interval '1 min') then 'in_progress'
              when NOW() < webconferences.initial_time then 'scheduled'
              when (NOW()<webconferences.initial_time + webconferences.duration* interval '1 min' + interval '15 mins') then 'processing'
            ELSE 'finish' 
            END AS situation,
            academic_allocations.evaluative,
            academic_allocations.frequency
          FROM webconferences, academic_allocations 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
          LEFT JOIN log_actions ON academic_allocations.id = log_actions.academic_allocation_id AND log_actions.log_type = 7 AND log_actions.user_id = #{user_id}
          LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id
          LEFT JOIN webconferences eq_web ON eq_web.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'Webconference'
          WHERE 
            academic_allocations.academic_tool_id = webconferences.id AND academic_allocations.academic_tool_type='Webconference' #{wq} #{ats_query}
          )"

        end
      end

      query = query.join(' UNION ')
      query + 'ORDER BY academic_tool_type, start_date, situation, name;'
  end


end
