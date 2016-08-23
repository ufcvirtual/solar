class Score # < ActiveRecord::Base

  
  def self.informations(user_id, at_id, related: nil)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)

    related = related || at.related

    history_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related).limit(5)
    public_files   = PublicFile.where(user_id: user_id, allocation_tag_id: at_id)
    count_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related).count
                        
    [history_access, public_files, count_access]
  end

  def self.list_tool(user_id, at_id, tool='all', evaluative=false, frequency=false, all=false)
    evaluated_status = if frequency
      "WHEN academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    elsif !all
      "WHEN academic_allocation_users.grade IS NOT NULL THEN 'evaluated'"
    else 
      "WHEN academic_allocation_users.grade IS NOT NULL OR academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    end

    sent_status = if frequency
      'academic_allocation_users.status = 1 OR (academic_allocation_users.status = 2 AND (academic_allocation_users.working_hours IS NULL OR academic_allocation_users.grade IS NULL))'
    else
      'academic_allocation_users.status = 1'
    end

    ats_ids = AllocationTag.find(at_id).related
    wq = "AND academic_allocations.evaluative=true " if evaluative
    wq = "AND academic_allocations.frequency=true "  if frequency
    wq = "AND academic_allocations.evaluative=false" if !evaluative && !frequency
    wq = '' if evaluative.blank? && frequency.blank? && all

    prepare_query = Score.get_query((tool == 'all' ? ['discussions','assignments','chat_rooms','webconferences','exams','schedule_events'] : [tool]), ats_ids.join(','), user_id, wq, sent_status, evaluated_status)

    User.find_by_sql prepare_query
  end

  def self.evaluative_frequency(ats, type_score='evaluative')
    evaluated_status = if type_score == 'frequency'
      "WHEN academic_allocation_users.working_hours IS NOT NULL THEN 'evaluated'"
    else
      "WHEN academic_allocation_users.grade IS NOT NULL THEN 'evaluated'"
    end

    sent_status = if type_score == 'frequency'
      'academic_allocation_users.status = 1 OR (academic_allocation_users.status = 2 AND (academic_allocation_users.working_hours IS NULL OR academic_allocation_users.grade IS NULL))'
    else
      'academic_allocation_users.status = 1'
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
        WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Assignment' AND (af.id IS NOT NULL OR (aw.id IS NOT NULL AND (is_recorded AND (initial_time + (interval '1 minutes')*duration) < now())))))) THEN 'sent'
        WHEN assignments.id IS NOT NULL AND assignments.type_assignment = #{Assignment_Type_Group} AND gp.id IS NULL THEN 'without_group'
        WHEN schedules.start_date  > current_date THEN 'not_started'
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
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean )

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
        WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'ChatRoom' AND chat_messages.id IS NOT NULL))) THEN 'sent'
        WHEN schedules.start_date > current_date OR (schedules.start_date = current_date AND current_time < cast(start_hour as time)) THEN 'not_started'
        WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (start_hour IS NULL OR current_time>cast(start_hour as time) ) AND (end_hour IS NULL OR current_time<=cast(end_hour as time)) THEN 'to_send'
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
    LEFT JOIN chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id AND (chat_messages.allocation_id = allocations.id OR chat_messages.user_id = users.id)
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ))

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
        WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Discussion' AND discussion_posts.id IS NOT NULL))) THEN 'sent'
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
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ))
    
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
        WHEN current_date <= schedules.start_date OR current_time<=cast(start_hour as time) THEN 'not_started'
        WHEN ((current_date >= schedules.start_date AND current_time>= CASE WHEN start_hour IS NULL THEN time '00:00'  ELSE cast(start_hour as time) END) AND (current_date <= schedules.end_date AND current_time<CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)) THEN 'to_send'
        ELSE 
          'not_sent'
        END AS situation
    FROM users
    JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id IN (#{ats})
    JOIN profiles ON allocations.profile_id = profiles.id
    JOIN academic_allocations ON academic_allocations.allocation_tag_id IN (#{ats}) AND academic_tool_type='Exam'
    JOIN exams ON academic_allocations.academic_tool_id = exams.id
    JOIN schedules ON exams.schedule_id = schedules.id
     LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = users.id
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND exams.status = 't')
  
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
        WHEN current_date<schedules.start_date AND (start_hour IS NULL OR current_time<=cast(start_hour as time))  THEN 'not_started'
        WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND current_time>=cast(start_hour as time) AND current_time<=cast(end_hour as time) THEN 'to_send'
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
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ))

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
        WHEN webconferences.initial_time + (interval '1 hours')*webconferences.duration > now() THEN 'to_send'
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
    WHERE cast( profiles.types & '#{Profile_Type_Student}' as boolean ))
    
    ORDER BY acu_status, situation, academic_tool_type;
    SQL
    
  end

  def self.get_users(ats)
    User.find_by_sql <<-SQL
      SELECT DISTINCT users.id, users.name
      FROM users
      JOIN allocations ON allocations.user_id = users.id
      JOIN profiles ON profiles.id = allocations.profile_id
      WHERE allocations.allocation_tag_id IN (#{ats})
      AND cast( profiles.types & '#{Profile_Type_Student}' as boolean )
      ORDER BY name;
    SQL
  end

  private

    def self.get_query(tools, ats, user_id, wq, sent_status='', evaluated_status='')
      query = []

      tools.each do |tool|
        query << case tool
        when 'discussions'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type, 
            discussions.name AS name,
            discussions.description,
            s.start_date,
            s.end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            NULL AS group_id,
            --(SELECT COUNT(dp.id) 
            --  FROM discussion_posts dp) AS count,
            '' AS start_hour,
            '' AS end_hour,
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
            END AS situation
          FROM discussions, schedules s, academic_allocations 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
          LEFT JOIN discussion_posts ON discussion_posts.academic_allocation_id = academic_allocations.id AND discussion_posts.user_id = #{user_id}
          WHERE 
            academic_allocations.academic_tool_id = discussions.id AND academic_tool_type='Discussion' AND discussions.schedule_id=s.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats})
          )"

        when 'assignments'
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
                assignments.name AS name,
                assignments.enunciation AS description,
                schedules.start_date,
                schedules.end_date,
                academic_allocation_users.grade,
                academic_allocation_users.working_hours,
                academic_allocation_users.user_id,
                academic_allocation_users.new_after_evaluation,
                groups.group_id::text AS group_id,
                '' AS start_hour,
                '' AS end_hour,
                -- -- 0 as count,
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
                  when schedules.start_date > current_date                       then 'not_started'
                  when assignments.type_assignment = #{Assignment_Type_Group} AND groups.group_id IS NULL  then 'without_group'
                   when #{sent_status} OR academic_allocation_users.status = 1 OR academic_allocation_users.status = 1 OR attachment_updated_at IS NOT NULL OR (is_recorded AND (initial_time + (interval '1 mins')*duration) < now()) then 'sent'
                  when schedules.end_date >= current_date                        then 'to_be_sent'
                  when schedules.end_date < current_date                         then 'not_sent'
                  else  '-'
                 end AS situation
              FROM assignments, schedules, academic_allocations 
              LEFT JOIN (select group_id, ac_id from groups) AS groups ON groups.ac_id = academic_allocations.id
              LEFT JOIN academic_allocation_users ON academic_allocations.id = academic_allocation_users.academic_allocation_id AND (academic_allocation_users.user_id = #{user_id} OR (academic_allocation_users.group_assignment_id = groups.group_id))
              LEFT JOIN assignment_files ON assignment_files.academic_allocation_user_id = academic_allocation_users.id
              LEFT JOIN assignment_webconferences ON assignment_webconferences.academic_allocation_user_id = academic_allocation_users.id
              WHERE 
                academic_allocations.academic_tool_id = assignments.id AND academic_tool_type='Assignment' AND assignments.schedule_id=schedules.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats}) AND 
                (academic_allocation_users.id IS NULL OR (academic_allocation_users.user_id = #{user_id} OR (academic_allocation_users.group_assignment_id = groups.group_id AND assignments.type_assignment = #{Assignment_Type_Group}) OR (groups.group_id IS NULL AND assignments.type_assignment = #{Assignment_Type_Group})) OR (academic_allocation_users.user_id IS NULL AND academic_allocation_users.group_assignment_id IS NULL))
          )"
        when 'chat_rooms'
          "( SELECT DISTINCT
              academic_allocations.id, 
              academic_allocations.allocation_tag_id, 
              academic_allocations.academic_tool_id, 
              academic_allocations.academic_tool_type, 
              chat_rooms.title AS name,
              chat_rooms.description,
              schedules.start_date,
              schedules.end_date,
              academic_allocation_users.grade,
              academic_allocation_users.working_hours,
              academic_allocation_users.user_id,
              academic_allocation_users.new_after_evaluation,
              NULL AS group_id,
              start_hour,
              end_hour,
              -- 0 as count,
              CASE 
              WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (start_hour IS NULL OR current_time>cast(start_hour as time) ) AND (end_hour IS NULL OR current_time<=cast(end_hour as time)) THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN (current_date > schedules.end_date) OR (current_date = schedules.end_date AND (end_hour IS NULL OR current_time>cast(end_hour as time))) THEN true
              ELSE 
                false
              END AS closed,
              CASE 
                #{evaluated_status}   
                WHEN (#{sent_status} OR  academic_allocation_users.status = 1 OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'ChatRoom' AND chat_messages.id IS NOT NULL))) THEN 'sent'
                WHEN schedules.start_date > current_date OR (schedules.start_date = current_date AND current_time < cast(start_hour as time)) THEN 'not_started'
                WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (start_hour IS NULL OR current_time>cast(start_hour as time) ) AND (end_hour IS NULL OR current_time<=cast(end_hour as time)) THEN 'opened'
                ELSE
                'closed'
              END AS situation
            FROM chat_rooms, schedules, academic_allocations 
            LEFT JOIN allocations ON allocations.user_id = #{user_id} AND allocations.allocation_tag_id IN (#{ats})
            LEFT JOIN chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id AND (chat_messages.allocation_id = allocations.id OR chat_messages.user_id = #{user_id})
            LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
            LEFT JOIN chat_participants ON chat_participants.academic_allocation_id = academic_allocations.id AND chat_participants.allocation_id = allocations.id
            WHERE 
              academic_allocations.academic_tool_id = chat_rooms.id AND academic_tool_type='ChatRoom' AND chat_rooms.schedule_id=schedules.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats}) AND (chat_rooms.chat_type = 0 OR chat_participants.id IS NOT NULL)
            )"

        when 'exams'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type, 
            exams.name AS name,
            exams.description,
            s.start_date,
            s.end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            NULL AS group_id,
            start_hour,
            end_hour,
            -- 0 as count,
            CASE 
              WHEN (current_date >= s.start_date AND current_date <= s.end_date) AND (start_hour IS NULL OR current_time > cast(start_hour as time)) AND (end_hour IS NULL OR current_time < cast(end_hour as time)) THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN (current_date > s.end_date) AND (end_hour IS NULL OR current_time < cast(end_hour as time)) THEN true
              ELSE 
                false
              END AS closed,
            case
              when current_date <= s.start_date OR current_time<=cast(start_hour as time)    then 'not_started'
              when ((current_date >= s.start_date AND current_time>= CASE WHEN start_hour IS NULL THEN time '00:00'  ELSE cast(start_hour as time) END) AND (current_date <= s.end_date AND current_time<CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)) AND exam_responses.id IS NULL    then 'to_answer'
              when ((current_date >= s.start_date AND current_time>CASE WHEN start_hour IS NULL THEN time '00:00'  ELSE cast(start_hour as time) END) AND (current_date <= s.end_date AND current_time<CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)) AND exam_user_attempts.complete!=TRUE                                         then 'not_finished'
              when ((current_date >= s.start_date AND current_time>CASE WHEN start_hour IS NULL THEN time '00:00'  ELSE cast(start_hour as time) END) AND (current_date <= s.end_date AND current_time<CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)) AND (attempts > count(exam_user_attempts.id))                        then 'retake'
              when academic_allocation_users.grade IS NOT NULL AND (current_date >= s.end_date AND current_time>CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)                                        then 'corrected'
              when exam_user_attempts.complete=TRUE AND (attempts = count(exam_user_attempts.id))                        then 'finished'
              when (current_date >= s.end_date AND current_time>cast(end_hour as time)) AND (count(exam_user_attempts.id) > 0 ) AND academic_allocation_users.grade IS NULL then 'not_corrected'
              else
                'not_answered'
              end AS situation
          FROM exams, schedules s, academic_allocations LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
            LEFT JOIN exam_user_attempts ON exam_user_attempts.academic_allocation_user_id = academic_allocation_users.id
            LEFT JOIN exam_responses ON exam_responses.exam_user_attempt_id = exam_user_attempts.id 
          WHERE 
            academic_allocations.academic_tool_id = exams.id AND academic_tool_type='Exam' AND exams.schedule_id=s.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats}) 
            GROUP BY academic_allocations.id, academic_allocations.allocation_tag_id, academic_allocations.academic_tool_id, academic_allocations.academic_tool_type, exams.name,  s.start_date,  s.end_date, description, new_after_evaluation,
            academic_allocation_users.grade,  academic_allocation_users.working_hours, academic_allocation_users.user_id, start_hour, end_hour,  exam_responses.id, exam_user_attempts.complete, attempts
          ) "

        when 'schedule_events'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type, 
            schedule_events.title AS name,
            schedule_events.description,
            schedules.start_date,
            schedules.end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            NULL AS group_id,
            start_hour,
            end_hour,
            -- 0 as count,
            CASE 
              WHEN (current_date >= schedules.start_date AND current_date <= schedules.end_date) AND (start_hour IS NULL OR current_time > cast(start_hour as time)) AND (end_hour IS NULL OR current_time<=cast(end_hour as time)) THEN true
              ELSE 
                false
              END AS opened,
            CASE 
              WHEN (current_date > schedules.end_date) AND (end_hour IS NULL OR current_time>cast(start_hour as time)) THEN true
              ELSE 
                false
              END AS closed,
            CASE
            #{evaluated_status}
            WHEN current_date>schedules.end_date OR current_date=schedules.end_date AND current_time>cast(end_hour as time) THEN 'closed'
            WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND start_hour IS NULL THEN 'started'
            WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND current_time>=cast(start_hour as time) AND current_time<=cast(end_hour as time) THEN 'started'
            ELSE 'not_started'  
            END AS situation
          FROM schedule_events, schedules, academic_allocations 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
          WHERE 
            academic_allocations.academic_tool_id = schedule_events.id AND academic_tool_type='ScheduleEvent' AND schedule_events.schedule_id=schedules.id #{wq} AND academic_allocations.allocation_tag_id IN (#{ats})
          )"

        when 'webconferences'
          "(SELECT DISTINCT
            academic_allocations.id, 
            academic_allocations.allocation_tag_id, 
            academic_allocations.academic_tool_id, 
            academic_allocations.academic_tool_type, 
            webconferences.title AS name,
            webconferences.description,
            webconferences.initial_time AS start_date,
            webconferences.initial_time AS end_date,
            academic_allocation_users.grade,
            academic_allocation_users.working_hours,
            academic_allocation_users.user_id,
            academic_allocation_users.new_after_evaluation,
            NULL AS group_id,
            initial_time || '' AS start_hour,
            initial_time + duration* interval '1 min' || '' AS end_hour,
            -- 0 as count,
            CASE 
              when NOW()>initial_time AND NOW()<=(initial_time + duration* interval '1 min') then true
              ELSE 
                false
              END AS opened,
            CASE 
              when NOW()>(initial_time + duration* interval '1 min') then true
              ELSE 
                false
              END AS closed,
            CASE
              #{evaluated_status}
              WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Webconference' AND log_actions.id IS NOT NULL))) THEN 'sent'
              when NOW()>initial_time AND NOW()<(initial_time + duration* interval '1 min') then 'in_progress'
              when NOW() < initial_time then 'scheduled'
              when is_recorded AND (NOW()>initial_time + duration* interval '1 min' + interval '10 mins') then'record_available' 
              when is_recorded AND (NOW()<initial_time + duration* interval '1 min' + interval '10 mins') then 'processing'
            ELSE 'finish' 
            END AS situation
          FROM webconferences, academic_allocations 
          LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
          LEFT JOIN log_actions ON academic_allocations.id = log_actions.academic_allocation_id AND log_actions.log_type = 7 AND log_actions.user_id = #{user_id}
          WHERE 
            academic_allocations.academic_tool_id = webconferences.id AND academic_tool_type='Webconference' #{wq} AND academic_allocations.allocation_tag_id IN (#{ats})
          )"

        end
      end

      query = query.join(' UNION ')
      query + 'ORDER BY academic_tool_type, situation;'
  end


end
