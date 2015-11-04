module V1::GroupsH

  def get_group(params)
    group = (params[:group_id].nil? ? get_group_by_codes(params[:curriculum_unit_code], params[:course_code], params[:group_code], params[:semester]) : Group.find(params[:group_id]))
    raise ActiveRecord::RecordNotFound if group.nil?
  end

  def get_group_by_codes(curriculum_unit_code, course_code, code, semester)
    Group.joins(offer: :semester).where(code: code, 
      offers: {curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
               course_id: Course.where(code: course_code).first},
      semesters: {name: semester}).first
  end

  def get_offer_group(offer, group_code)
    offer.groups.where("lower(code) = lower(?)", group_code).first rescue ActiveRecord::RecordNotFound
  end

  def verify_or_create_group(params)
    group = Group.where(group_params(params)).first_or_initialize
    group.status = true
    group.save!
    group
  end

  def group_params(params)
    ActionController::Parameters.new(params).except("route_info").permit("code", "offer_id")
  end

  def get_group_students_info(allocation_tag_id, group)
    related_ats_ids    = group.allocation_tag.related.join(',')
    msg_outbox_query   = Message.get_query('users.id', 'outbox', [allocation_tag_id], { ignore_trash: false, ignore_user: true })
    recorded_meetings  = Webconference.first.bbb_all_recordings.map{|a| a[:meetingID]}.uniq
    @students          = User.find_by_sql <<-SQL
      SELECT users.cpf, users.name, users.gender, users.birthdate, users.address, users.address_number, users.address_complement, users.address_neighborhood, users.zipcode, users.city, users.state,
             COUNT(DISTINCT public_files.id)            AS count_public_files,
             COALESCE(all_sent_messages.count,0)        AS all_sent_msgs,
             COALESCE(all_resp_sent_messages.count,0)   AS all_resp_sent_msgs,
             COALESCE(logs.count,0)                     AS count_access,
             COALESCE(posts.count,0)                    AS count_posts,
             COALESCE(posts.count_discussions,0)        AS count_discussions,
             COALESCE(chat_messages.count,0)            AS count_chat_messages,
             COALESCE(chat_messages.count_chat_rooms,0) AS count_chat_rooms,
             COALESCE(webs.count,0)                     AS count_web_access,
             COALESCE(webs.count_webconferences,0)      AS count_webs,
             COALESCE(assignments.count,0)              AS count_assignments
           FROM users
           JOIN allocations  ON allocations.user_id     = users.id
           JOIN profiles     ON allocations.profile_id  = profiles.id
      LEFT JOIN public_files ON public_files.user_id    = users.id AND public_files.allocation_tag_id = #{allocation_tag_id}
      LEFT JOIN (
         SELECT COUNT(DISTINCT log_accesses.id) AS count, log_accesses.user_id AS user_id
         FROM log_accesses
         JOIN allocation_tags ON allocation_tags.id = log_accesses.allocation_tag_id
         LEFT JOIN merges ON (allocation_tags.group_id = merges.secundary_group_id OR allocation_tags.group_id = merges.main_group_id)
         WHERE (
            merges.main_group_id = #{group.id}
            OR
            merges.secundary_group_id = #{group.id}
            OR
            allocation_tags.id IN (#{related_ats_ids})
          )
          AND log_accesses.log_type = #{LogAccess::TYPE[:group_access]}
         GROUP BY log_accesses.user_id
      ) logs ON logs.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(messages.id) AS count, user_messages.user_id AS user_id
        FROM messages
        JOIN user_messages ON user_messages.message_id = messages.id
        WHERE #{msg_outbox_query}
        GROUP BY user_messages.user_id
      ) all_sent_messages ON all_sent_messages.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(DISTINCT messages.id) AS count, um2.user_id AS user_id
        FROM messages
        JOIN user_messages um2 ON um2.message_id = messages.id
        JOIN user_messages um1 ON um2.message_id = um1.message_id
        JOIN allocations   al2 ON al2.user_id    = um1.user_id    AND al2.status = #{Allocation_Activated}
        JOIN profiles      p   ON p.id           = al2.profile_id AND cast(p.types & #{Profile_Type_Class_Responsible} as boolean)
        WHERE cast(um2.status & #{Message_Filter_Sender} as boolean)
        AND (um1.status = 0 OR um1.status = 2 OR cast(um1.status & #{Message_Filter_Read + Message_Filter_Trash} as boolean))
        AND messages.allocation_tag_id IN (#{related_ats_ids})
        GROUP BY um2.user_id
      ) all_resp_sent_messages ON all_resp_sent_messages.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(discussion_posts.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_discussions, discussion_posts.user_id AS user_id
        FROM discussion_posts
        JOIN academic_allocations ON academic_allocations.id = discussion_posts.academic_allocation_id 
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        GROUP BY discussion_posts.user_id
      ) posts ON posts.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(chat_messages.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_chat_rooms, u2.id AS user_id
        FROM chat_messages
        JOIN academic_allocations ON academic_allocations.id     = chat_messages.academic_allocation_id
        JOIN allocations          ON chat_messages.allocation_id = allocations.id
        JOIN users u2             ON u2.id                       = allocations.user_id
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        AND message_type = 1
        GROUP BY u2.id
      ) chat_messages ON chat_messages.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(log_actions.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_webconferences, log_actions.user_id AS user_id
        FROM log_actions
        JOIN academic_allocations ON academic_allocations.id = log_actions.academic_allocation_id
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        AND log_actions.log_type = #{LogAction::TYPE[:access_webconference]}
        GROUP BY log_actions.user_id
      ) webs ON webs.user_id = users.id
      LEFT JOIN (
        SELECT COALESCE(sent_assignments.user_id, gp.user_id, 0) AS user_id, COUNT(assignments.id) AS count
        FROM sent_assignments
        JOIN academic_allocations              ON academic_allocations.id = sent_assignments.academic_allocation_id
        JOIN assignments                       ON assignments.id = academic_allocations.academic_tool_id
        JOIN schedules                         ON assignments.schedule_id = schedules.id
        LEFT JOIN group_assignments ga         ON sent_assignments.group_assignment_id = ga.id
        LEFT JOIN group_participants gp        ON gp.group_assignment_id  = ga.id
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        AND (
          EXISTS (
            SELECT id
            FROM assignment_webconferences
            WHERE sent_assignment_id = sent_assignments.id
            AND (initial_time + (interval '1 minutes')*duration)::date <= schedules.end_date 
            AND (
              (position(COALESCE(origin_meeting_id, ('aw_' || assignment_webconferences.id || ',')) in '#{recorded_meetings.join(',')}') > 0)
              OR
              (position(COALESCE(origin_meeting_id, ('aw_' || assignment_webconferences.id)) in '#{recorded_meetings.join(',')}') = (octet_length('#{recorded_meetings.join(',')}') - octet_length(COALESCE(origin_meeting_id, ('aw_' || assignment_webconferences.id)))))
            )
          )
          OR EXISTS (
            SELECT id 
            FROM assignment_files 
            WHERE sent_assignment_id = sent_assignments.id AND attachment_file_name IS NOT NULL
          )
        )
        GROUP BY COALESCE(sent_assignments.user_id, gp.user_id, 0)
      ) assignments ON assignments.user_id = users.id
      WHERE 
        allocations.allocation_tag_id = #{allocation_tag_id}
        AND cast(profiles.types & #{Profile_Type_Student} as boolean)
        AND allocations.status        = #{Allocation_Activated}
        AND users.active              = 't'
      GROUP BY users.id, all_sent_messages.count, all_resp_sent_messages.count, logs.count, posts.count, posts.count_discussions, chat_messages.count, chat_messages.count_chat_rooms, webs.count, webs.count_webconferences, assignments.count
    SQL
  end

  def get_group_info(group)
    recorded_meetings  = Webconference.first.bbb_all_recordings.map{|a| a[:meetingID]}.uniq
    related_ats        = group.allocation_tag.related.join(',')
    @group             = Group.find_by_sql <<-SQL
      SELECT groups.id,
             COUNT(DISTINCT public_files.id)            AS count_public_files,
             COALESCE(assignments.count,0)              AS count_assignments,
             COALESCE(discussions.count,0)              AS count_discussions,
             COALESCE(webconferences.count,0)           AS count_webconferences,
             COALESCE(chat_rooms.count,0)               AS count_chat_rooms,
             COUNT(DISTINCT messages.id)                AS all_sent_msgs
           FROM groups
           JOIN offers                ON groups.offer_id            = offers.id
           JOIN curriculum_units      ON offers.curriculum_unit_id  = curriculum_units.id
           JOIN courses               ON offers.course_id           = courses.id
           JOIN semesters             ON offers.semester_id         = semesters.id
           JOIN allocation_tags       ON allocation_tags.group_id   = groups.id OR allocation_tags.offer_id = offers.id
      LEFT JOIN academic_allocations  ON allocation_tags.id         = academic_allocations.allocation_tag_id
      LEFT JOIN public_files          ON allocation_tags.id         = public_files.allocation_tag_id
      LEFT JOIN messages              ON allocation_tags.id         = messages.allocation_tag_id
      LEFT JOIN (
        SELECT COUNT(DISTINCT assignments.id) AS count, academic_allocations.allocation_tag_id AS at FROM assignments
        JOIN academic_allocations ON academic_allocations.academic_tool_id = assignments.id AND academic_tool_type = 'Assignment'
        GROUP BY academic_allocations.allocation_tag_id
      ) assignments ON assignments.at = allocation_tags.id 
      LEFT JOIN (
        SELECT COUNT(DISTINCT discussions.id) AS count, academic_allocations.allocation_tag_id AS at  FROM discussions
        JOIN academic_allocations ON academic_allocations.academic_tool_id = discussions.id AND academic_tool_type = 'Discussion'
        GROUP BY academic_allocations.allocation_tag_id
      ) discussions ON discussions.at = allocation_tags.id 
      LEFT JOIN (
        SELECT COUNT(DISTINCT chat_rooms.id) AS count, academic_allocations.allocation_tag_id AS at FROM chat_rooms
        JOIN academic_allocations ON chat_rooms.id = academic_allocations.academic_tool_id AND academic_tool_type = 'ChatRoom'
        GROUP BY academic_allocations.allocation_tag_id
      ) chat_rooms ON chat_rooms.at = allocation_tags.id 
      LEFT JOIN (
        SELECT COUNT(DISTINCT webconferences.id) AS count, academic_allocations.allocation_tag_id AS at  FROM webconferences
        JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id AND academic_tool_type = 'Webconference'
        GROUP BY academic_allocations.allocation_tag_id
      ) webconferences ON webconferences.at = allocation_tags.id 
      WHERE groups.id = #{group.id}
      GROUP BY groups.id, assignments.count, webconferences.count, discussions.count, chat_rooms.count;
    SQL

    chat_msgs = ChatMessage.find_by_sql <<-SQL
      SELECT COUNT(DISTINCT chat_messages.id) FROM chat_messages
        JOIN academic_allocations ON chat_messages.academic_allocation_id  = academic_allocations.id
        WHERE message_type = 1 AND academic_allocations.allocation_tag_id IN (#{related_ats})
        GROUP BY academic_allocations.allocation_tag_id
    SQL
    @chat_msgs = chat_msgs.first.try(:count)

    posts = Post.find_by_sql <<-SQL
        SELECT COUNT(DISTINCT discussion_posts.id) AS count, academic_allocations.allocation_tag_id AS at FROM discussion_posts
        JOIN academic_allocations ON discussion_posts.academic_allocation_id = academic_allocations.id
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats})
        GROUP BY academic_allocations.allocation_tag_id
    SQL
    @posts = posts.first.try(:count)

    web_access = LogAction.find_by_sql <<-SQL 
        SELECT COUNT(DISTINCT log_actions.id) AS count, academic_allocations.allocation_tag_id AS at FROM log_actions
        JOIN academic_allocations ON academic_allocations.id = log_actions.academic_allocation_id
       WHERE log_actions.log_type = #{LogAction::TYPE[:access_webconference]}
       AND academic_allocations.allocation_tag_id IN (#{related_ats})
       GROUP BY academic_allocations.allocation_tag_id
      SQL
    @web_access = web_access.first.try(:count)

    allocations = Allocation.find_by_sql <<-SQL 
        SELECT COUNT(DISTINCT allocations.user_id) AS count, allocations.allocation_tag_id AS at
        FROM allocations
        JOIN profiles ON allocations.profile_id = profiles.id
        WHERE allocations.status = #{Allocation_Activated}
        AND cast(profiles.types & #{Profile_Type_Student} as boolean)
        AND allocations.allocation_tag_id IN (#{related_ats})
        GROUP BY allocations.allocation_tag_id
    SQL
    @allocations = allocations.first.try(:count)

    deactivated_allocations = Allocation.find_by_sql <<-SQL 
        SELECT COUNT(DISTINCT allocations.user_id) AS count, allocations.allocation_tag_id AS at
        FROM allocations
        JOIN profiles ON allocations.profile_id = profiles.id
        WHERE allocations.status = #{Allocation_Cancelled}
        AND cast(profiles.types & #{Profile_Type_Student} as boolean)
        AND allocations.allocation_tag_id IN (#{related_ats})
        GROUP BY allocations.allocation_tag_id
    SQL
    @deactivated_allocations = deactivated_allocations.first.try(:count)

    messages_to_responsible = Message.find_by_sql <<-SQL
     SELECT COUNT(DISTINCT messages.id) AS count FROM messages
      JOIN user_messages um2 ON um2.message_id = messages.id
      JOIN user_messages um1 ON um2.message_id = um1.message_id
      JOIN allocations   al1 ON al1.user_id    = um1.user_id    AND al1.status = #{Allocation_Activated}
      JOIN allocations   al2 ON al2.user_id    = um2.user_id    AND al2.status = #{Allocation_Activated}
      JOIN profiles      p1  ON p1.id          = al1.profile_id AND cast(p1.types & #{Profile_Type_Class_Responsible} as boolean)
      JOIN profiles      p2  ON p2.id          = al2.profile_id AND (cast(p2.types & #{Profile_Type_Class_Responsible} as boolean) OR cast(p2.types & #{Profile_Type_Student} as boolean))
      WHERE (um1.status = 0 OR um1.status = 2 OR cast(um1.status & #{Message_Filter_Read + Message_Filter_Trash} as boolean))
      AND cast(um2.status & #{Message_Filter_Sender} as boolean)
      AND messages.allocation_tag_id IN (#{related_ats})
    SQL
    @messages_to_responsible = messages_to_responsible.first.try(:count)

    sent_assignments = SentAssignment.find_by_sql <<-SQL
     SELECT COUNT(DISTINCT sent_assignments.id) AS count
        FROM sent_assignments
        JOIN academic_allocations              ON academic_allocations.id = sent_assignments.academic_allocation_id AND academic_allocations.allocation_tag_id IN (#{related_ats})
        JOIN assignments                       ON assignments.id          = academic_allocations.academic_tool_id
        JOIN schedules                         ON assignments.schedule_id = schedules.id
        LEFT JOIN group_assignments  ga        ON sent_assignments.group_assignment_id = ga.id
        LEFT JOIN group_participants gp        ON gp.group_assignment_id  = ga.id
        WHERE (
          EXISTS (
            SELECT id
            FROM assignment_webconferences
            WHERE sent_assignment_id = sent_assignments.id
            AND (initial_time + (interval '1 minutes')*duration)::date <= schedules.end_date 
            AND (
              (position(COALESCE(origin_meeting_id, ('aw_' || assignment_webconferences.id || ',')) in '#{recorded_meetings.join(',')}') > 0)
              OR
              (position(COALESCE(origin_meeting_id, ('aw_' || assignment_webconferences.id)) in '#{recorded_meetings.join(',')}') = (octet_length('#{recorded_meetings.join(',')}') - octet_length(COALESCE(origin_meeting_id, ('aw_' || assignment_webconferences.id)))))
            )
          )
          OR EXISTS (
            SELECT id 
            FROM assignment_files 
            WHERE sent_assignment_id = sent_assignments.id AND attachment_file_name IS NOT NULL
          )
        )
    SQL
    @sent_assignments = sent_assignments.first.try(:count)
  end

  def get_group_responsible_info(user_id, allocation_tag_id, group)
    related_ats_ids    = group.allocation_tag.related.join(',')
    msg_outbox_query   = Message.get_query('users.id', 'outbox', [allocation_tag_id], { ignore_trash: false, ignore_user: true })
    recorded_meetings  = Webconference.first.bbb_all_recordings.map{|a| a[:meetingID]}.uniq
    @user              = User.find_by_sql <<-SQL
      SELECT COUNT(DISTINCT public_files.id)            AS count_public_files,
             COALESCE(all_sent_messages.count,0)        AS all_sent_msgs,
             COALESCE(logs.count,0)                     AS count_access,
             COALESCE(posts.count,0)                    AS count_posts,
             COALESCE(posts.count_discussions,0)        AS count_discussions,
             COALESCE(chat_messages.count,0)            AS count_chat_messages,
             COALESCE(chat_messages.count_chat_rooms,0) AS count_chat_rooms,
             COALESCE(webs.count,0)                     AS count_web_access,
             COALESCE(webs.count_webconferences,0)      AS count_webs,
             COALESCE(comments.total,0)                 AS count_comments,
             COALESCE(comments.sa,0)                    AS count_sent_assignments_with_comments,
             COALESCE(comments.assig,0)                 AS count_assignments_with_comments,
             COALESCE(grades.count,0)                   AS count_sent_assignments_assignments_with_grades,
             COALESCE(grades.assig,0)                   AS count_assignments_with_grades
           FROM users
           JOIN allocations  ON allocations.user_id     = users.id
           JOIN profiles     ON allocations.profile_id  = profiles.id
      LEFT JOIN public_files ON public_files.user_id    = users.id AND public_files.allocation_tag_id = #{allocation_tag_id}
      LEFT JOIN (
         SELECT COUNT(DISTINCT log_accesses.id) AS count, log_accesses.user_id AS user_id
         FROM log_accesses
         JOIN allocation_tags ON allocation_tags.id = log_accesses.allocation_tag_id
         LEFT JOIN merges ON (allocation_tags.group_id = merges.secundary_group_id OR allocation_tags.group_id = merges.main_group_id)
         WHERE (
            merges.main_group_id = #{group.id}
            OR
            merges.secundary_group_id = #{group.id}
            OR
            allocation_tags.id IN (#{related_ats_ids})
          )
          AND log_accesses.log_type = #{LogAccess::TYPE[:group_access]}
         GROUP BY log_accesses.user_id
      ) logs ON logs.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(messages.id) AS count, user_messages.user_id AS user_id
        FROM messages
        JOIN user_messages ON user_messages.message_id = messages.id
        WHERE #{msg_outbox_query}
        GROUP BY user_messages.user_id
      ) all_sent_messages ON all_sent_messages.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(discussion_posts.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_discussions, discussion_posts.user_id AS user_id
        FROM discussion_posts
        JOIN academic_allocations ON academic_allocations.id = discussion_posts.academic_allocation_id 
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        GROUP BY discussion_posts.user_id
      ) posts ON posts.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(chat_messages.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_chat_rooms, u2.id AS user_id
        FROM chat_messages
        JOIN academic_allocations ON academic_allocations.id     = chat_messages.academic_allocation_id
        JOIN allocations          ON chat_messages.allocation_id = allocations.id
        JOIN users u2             ON u2.id                       = allocations.user_id
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        AND message_type = 1
        GROUP BY u2.id
      ) chat_messages ON chat_messages.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(log_actions.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_webconferences, log_actions.user_id AS user_id
        FROM log_actions
        JOIN academic_allocations ON academic_allocations.id = log_actions.academic_allocation_id
        WHERE academic_allocations.allocation_tag_id IN (#{related_ats_ids})
        AND log_actions.log_type = #{LogAction::TYPE[:access_webconference]}
        GROUP BY log_actions.user_id
      ) webs ON webs.user_id = users.id
      LEFT JOIN (
        SELECT assignment_comments.user_id, COUNT(assignment_comments.id) AS total, COUNT(DISTINCT sent_assignments.id) AS sa, COUNT(DISTINCT assignments.id) AS assig
        FROM sent_assignments
        JOIN academic_allocations AS ac ON ac.id = sent_assignments.academic_allocation_id
        JOIN assignments                ON assignments.id = ac.academic_tool_id AND ac.academic_tool_type = 'Assignment'
        LEFT JOIN assignment_comments   ON assignment_comments.sent_assignment_id = sent_assignments.id
	WHERE ac.allocation_tag_id IN (#{related_ats_ids}) 
        GROUP BY assignment_comments.user_id
      ) comments ON comments.user_id = users.id
      LEFT JOIN (
        SELECT COUNT(sent_assignments.id) AS count, ac.allocation_tag_id AS at, COUNT(DISTINCT assignments.id) AS assig
        FROM sent_assignments
        JOIN academic_allocations AS ac ON ac.id = sent_assignments.academic_allocation_id
        JOIN assignments                ON assignments.id = ac.academic_tool_id AND ac.academic_tool_type = 'Assignment'
        WHERE ac.allocation_tag_id IN (#{related_ats_ids}) 
        AND sent_assignments.grade IS NOT NULL
        GROUP BY ac.allocation_tag_id
      ) grades ON grades.at IN (#{related_ats_ids})
      WHERE 
        allocations.allocation_tag_id = #{allocation_tag_id}
        AND cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)
        AND allocations.status = #{Allocation_Activated}
        AND users.id           = #{user_id}
      GROUP BY users.id, all_sent_messages.count, logs.count, posts.count, posts.count_discussions, chat_messages.count, chat_messages.count_chat_rooms, webs.count, webs.count_webconferences, assignments.count, assignments.sa, comments.total, comments.sa, comments.assig, grades.count, grades.assig
    SQL
    @user.first
  end

end
