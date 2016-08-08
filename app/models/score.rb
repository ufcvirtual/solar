class Score # < ActiveRecord::Base

  
  def self.informations(user_id, at_id, related: nil)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)

    history_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related || at.related).limit(5)
    public_files   = PublicFile.where(user_id: user_id, allocation_tag_id: at_id)
                        
    [history_access, public_files]
  end

  def self.list_tool(user_id, at_id, evaluative=false, frequency=false)
  	all_tags = AllocationTag.find(at_id).related
  	wq = "AND academic_allocations.evaluative=true " if evaluative
    wq = "AND academic_allocations.frequency=true " if frequency
    wq = "AND academic_allocations.evaluative=false AND academic_allocations.frequency=false " if !evaluative && !frequency
  	User.find_by_sql "SELECT 
		  academic_allocations.id, 
		  academic_allocations.allocation_tag_id, 
		  academic_allocations.academic_tool_id, 
		  academic_allocations.academic_tool_type,  
		  assignments.name,
		  schedules.start_date,
		  schedules.end_date,
		  academic_allocation_users.grade,
		  academic_allocation_users.working_hours,
		  academic_allocation_users.user_id,
		  '' AS start_hour,
		  '' AS end_hour,
		  case
		    when schedules.start_date > current_date		               then 'not_started'
		    when (assignments.type_assignment = 1 AND NOT EXISTS (SELECT MIN(group_assignments.id) FROM group_assignments, group_participants WHERE group_participants.group_assignment_id = group_assignments.id AND group_participants.user_id=7 AND group_assignments.academic_allocation_id=9)) 	       then 'without_group'
		    when grade IS NOT NULL                                             then 'corrected'
		    when EXISTS (SELECT MAX(max_date) FROM (SELECT MAX(initial_time) AS max_date FROM assignment_webconferences WHERE academic_allocation_user_id = academic_allocation_users.id
				AND is_recorded = 't' AND (initial_time + (interval '1 minutes')*duration) < now() UNION SELECT MAX(attachment_updated_at) AS max_date FROM assignment_files 
				WHERE attachment_updated_at IS NOT NULL AND academic_allocation_user_id = academic_allocation_users.id) AS max)    then 'sent'
		    when (schedules.end_date >= current_date)                          then 'to_be_sent'
		    when (schedules.end_date < current_date)                           then 'not_sent'
		    else
		      '-'
		    end AS situation
		FROM assignments, schedules, academic_allocations 
		LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id 
LEFT JOIN users ON users.id = academic_allocation_users.user_id 
LEFT JOIN group_participants gp ON gp.user_id = users.id AND (users.id=#{user_id} OR gp.user_id=#{user_id})
LEFT JOIN group_assignments ga ON ga.id = gp.group_assignment_id AND ga.academic_allocation_id = academic_allocations.id AND academic_allocations.academic_tool_type = 'Assignment' 
		WHERE 
		  academic_allocations.academic_tool_id = assignments.id AND academic_tool_type='Assignment' AND assignments.schedule_id=schedules.id #{wq} AND allocation_tag_id IN (#{at_id}) UNION (SELECT 
		  academic_allocations.id, 
		  academic_allocations.allocation_tag_id, 
		  academic_allocations.academic_tool_id, 
		  academic_allocations.academic_tool_type, 
		  chat_rooms.title,
		  schedules.start_date,
		  schedules.end_date,
		  academic_allocation_users.grade,
		  academic_allocation_users.working_hours,
		  academic_allocation_users.user_id,
		  start_hour,
		  end_hour,
		  CASE 
		    WHEN schedules.start_date > current_date THEN 'not_started'
		    WHEN schedules.end_date < current_date THEN 'closed'
		  END AS situation
		FROM chat_rooms, schedules, academic_allocations LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
		WHERE 
		  academic_allocations.academic_tool_id = chat_rooms.id AND academic_tool_type='ChatRoom' AND chat_rooms.schedule_id=schedules.id #{wq} AND allocation_tag_id IN (#{at_id})) UNION (SELECT 
		  academic_allocations.id, 
		  academic_allocations.allocation_tag_id, 
		  academic_allocations.academic_tool_id, 
		  academic_allocations.academic_tool_type, 
		  discussions.name,
		  s.start_date,
		  s.end_date,
		  academic_allocation_users.grade,
		  academic_allocation_users.working_hours,
		  academic_allocation_users.user_id,
		  '' AS start_hour,
		  '' AS end_hour,
		  CASE
		   WHEN s.start_date > current_date THEN 'not_started'
		   WHEN s.start_date <= current_date AND s.end_date >= current_date THEN 'opened'
		   WHEN s.end_date < current_date THEN 'closed'
		  END AS situation
		FROM discussions, schedules s, academic_allocations LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
		WHERE 
		  academic_allocations.academic_tool_id = discussions.id AND academic_tool_type='Discussion' AND discussions.schedule_id=s.id #{wq} AND allocation_tag_id IN (#{all_tags.join(',')})) UNION
		(SELECT 
		  academic_allocations.id, 
		  academic_allocations.allocation_tag_id, 
		  academic_allocations.academic_tool_id, 
		  academic_allocations.academic_tool_type, 
		  exams.name,
		  s.start_date,
		  s.end_date,
		  academic_allocation_users.grade,
		  academic_allocation_users.working_hours,
		  academic_allocation_users.user_id,
		  start_hour,
		  end_hour,
		  case
		    when current_date <= s.start_date OR current_time<=cast(start_hour as time)    then 'not_started'
		    when ((current_date >= s.start_date AND current_time>= CASE WHEN start_hour IS NULL THEN time '00:00'  ELSE cast(start_hour as time) END) AND (current_date <= s.end_date AND current_time<CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)) AND exam_responses.id IS NULL    then 'to_answer'
		    when ((current_date >= s.start_date AND current_time>CASE WHEN start_hour IS NULL THEN time '00:00'  ELSE cast(start_hour as time) END) AND (current_date <= s.end_date AND current_time<CASE WHEN end_hour IS NULL THEN time '23:59'  ELSE cast(end_hour as time) END)) AND exam_user_attempts.complete=TRUE                                         then 'not_finished'
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
		  academic_allocations.academic_tool_id = exams.id AND academic_tool_type='Exam' AND exams.schedule_id=s.id #{wq} AND allocation_tag_id IN (#{at_id}) GROUP BY academic_allocations.id, 
		  academic_allocations.allocation_tag_id, academic_allocations.academic_tool_id, academic_allocations.academic_tool_type, exams.name,  s.start_date,  s.end_date,
		  academic_allocation_users.grade,  academic_allocation_users.working_hours, academic_allocation_users.user_id, start_hour, end_hour,  exam_responses.id, exam_user_attempts.complete, attempts) UNION
		(SELECT 
		  academic_allocations.id, 
		  academic_allocations.allocation_tag_id, 
		  academic_allocations.academic_tool_id, 
		  academic_allocations.academic_tool_type, 
		  schedule_events.title,
		  schedules.start_date,
		  schedules.end_date,
		  academic_allocation_users.grade,
		  academic_allocation_users.working_hours,
		  academic_allocation_users.user_id,
		  start_hour,
		  end_hour,
		  CASE WHEN current_date>schedules.end_date OR current_date=schedules.end_date AND current_time>cast(end_hour as time) THEN 'closed'
       		   WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND start_hour IS NULL THEN 'started'
      		   WHEN current_date>=schedules.start_date AND current_date<=schedules.end_date AND current_time>=cast(start_hour as time) AND current_time<=cast(end_hour as time) THEN 'started'
       	  ELSE 'not_started'  END AS situation
		FROM schedule_events, schedules, academic_allocations LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
		WHERE 
		  academic_allocations.academic_tool_id = schedule_events.id AND academic_tool_type='ScheduleEvent' AND schedule_events.schedule_id=schedules.id #{wq} AND allocation_tag_id IN (#{at_id})) UNION
		(SELECT 
		  academic_allocations.id, 
		  academic_allocations.allocation_tag_id, 
		  academic_allocations.academic_tool_id, 
		  academic_allocations.academic_tool_type, 
		  webconferences.title,
		  webconferences.initial_time,
		  webconferences.created_at,
		  academic_allocation_users.grade,
		  academic_allocation_users.working_hours,
		  academic_allocation_users.user_id,
		  initial_time || '' AS start_hour,
		  '' AS end_hour,
		  CASE
		    when NOW()>initial_time AND NOW()<(initial_time + duration* interval '1 min') then 'in_progress'
		    when NOW() < initial_time then 'scheduled'
		    when is_recorded AND (NOW()>initial_time + duration* interval '1 min' + interval '10 mins') then'record_available' 
		    when is_recorded AND (NOW()<initial_time + duration* interval '1 min' + interval '10 mins') then 'processing'
		  ELSE 'finish' END AS situation
		FROM webconferences, academic_allocations LEFT JOIN academic_allocation_users ON academic_allocations.id =  academic_allocation_users.academic_allocation_id AND academic_allocation_users.user_id = #{user_id}
		WHERE 
		  academic_allocations.academic_tool_id = webconferences.id AND academic_tool_type='Webconference' #{wq} AND allocation_tag_id IN (#{at_id}))
		  ORDER BY academic_tool_type;"
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
        WHEN (#{sent_status} OR (academic_allocation_users.status IS NULL AND (academic_allocations.academic_tool_type = 'Assignment' AND (af.id IS NOT NULL OR aw.id IS NOT NULL)))) THEN 'sent'
        WHEN assignments.id IS NOT NULL AND assignments.type_assignment = #{Assignment_Type_Group} AND gp.id IS NULL THEN 'without_group'
        WHEN schedules.start_date + (interval '1 hours')*0 + (interval '1 minutes')*0 > now() THEN 'not_started'
        WHEN schedules.end_date + (interval '1 hours')*23 + (interval '1 minutes')*59 + (interval '1 seconds')*59 > now() THEN 'to_send'
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
        WHEN schedules.start_date + ((interval '1 hours')*(left(chat_rooms.start_hour, 2)::integer)) + ((interval '1 minutes')*(right(chat_rooms.start_hour, 2)::integer)) > now() THEN 'not_started'
        WHEN schedules.end_date + ((interval '1 hours')*(left(chat_rooms.end_hour, 2)::integer)) + ((interval '1 minutes')*(right(chat_rooms.end_hour, 2)::integer)) > now() THEN 'to_send'
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
        WHEN schedules.start_date + (interval '1 hours')*0 + (interval '1 minutes')*0 > now() THEN 'not_started'
        WHEN schedules.end_date + (interval '1 hours')*23 + (interval '1 minutes')*59 + (interval '1 seconds')*59 > now() THEN 'to_send'
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
        WHEN (schedules.start_date + (interval '1 hours')*(left(COALESCE(NULLIF(exams.start_hour, ''), '0'), 2)::integer) + (interval '1 minutes')*(right(COALESCE(NULLIF(exams.start_hour, ''), '0'), 2)::integer)) > now() THEN 'not_started'
        WHEN (schedules.end_date + (interval '1 hours')*(left(COALESCE(NULLIF(exams.end_hour, ''), '29'), 2)::integer) + (interval '1 minutes')*(right(COALESCE(NULLIF(exams.end_hour, ''), '59'), 2)::integer)) > now() THEN 'to_send'
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
        WHEN (schedules.start_date + (interval '1 hours')*(left(COALESCE(NULLIF(schedule_events.start_hour, ''), '0'), 2)::integer) + (interval '1 minutes')*(right(COALESCE(NULLIF(schedule_events.start_hour, ''), '0'), 2)::integer)) > now() THEN 'not_started'
        WHEN (schedules.end_date + (interval '1 hours')*(left(COALESCE(NULLIF(schedule_events.end_hour, ''), '29'), 2)::integer) + (interval '1 minutes')*(right(COALESCE(NULLIF(schedule_events.end_hour, ''), '59'), 2)::integer)) > now() THEN 'to_send'
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

end
