class LogAccess < ActiveRecord::Base

  belongs_to :user
  belongs_to :allocation_tag

  #default_scope order: 'created_at DESC'


  TYPE = {
    login: 1,
    group_access: 2
  }

  def order
   'created_at DESC'
  end

  def type_name
    type = case log_type
      when 1
        :login
      when 2
        :group_access
    end
    I18n.t(type, scope: 'administrations.logs.types')
  end

  def self.group(params)
    params.merge!(log_type: TYPE[:group_access])
    create(params)
  end

  def self.login(params)
    params.merge!(log_type: TYPE[:login])
    create(params)
  end

  def logs_by_user(ats)
    @logs = LogAccess.find_by_sql <<-SQL
    SELECT datetime, action, tool, tool_type, info FROM temp_logs_nav_sub WHERE user_id=#{self.student}
    UNION
    SELECT datetime, action, tool, tool_type, info FROM temp_logs_chat_messages WHERE user_id=#{self.student}
    UNION
    SELECT datetime, action, tool, tool_type, info FROM temp_logs_navigation WHERE user_id=#{self.student}
    UNION
    SELECT to_char(created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime, CASE WHEN log_type=1 THEN 'acessou o Solar' ELSE 'acessou turma' END AS action,  '' AS tool, '' AS tool_type, ''::text AS info
      FROM log_accesses WHERE log_accesses.user_id = #{self.student} AND (allocation_tag_id IS NULL OR log_accesses.allocation_tag_id IN (#{ats.join(',')}))
    UNION
    SELECT datetime, action, tool, tool_type, info FROM temp_logs_comments WHERE (user_id=#{self.student} OR group_user_id=#{self.student})
    UNION

    SELECT DISTINCT to_char(messages.created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
      'recebeu mensagem de responsável' AS action,
      messages.id::text AS tool,
      'Mensagem' AS tool_type,
      CASE
       WHEN  cast(user_student.status & #{Message_Filter_Read} as boolean)=TRUE THEN '(lida)'
       ELSE ''
      END AS info
    FROM
      messages LEFT JOIN user_messages AS user_prof ON messages.id = user_prof.message_id AND (user_prof.status=1 OR user_prof.status=3)
      LEFT JOIN allocations ON user_prof.user_id = allocations.user_id
      LEFT JOIN profiles ON allocations.profile_id = profiles.id
      LEFT JOIN user_messages AS user_student ON messages.id = user_student.message_id AND user_student.user_id=#{self.student} AND NOT cast(user_student.status & #{Message_Filter_Sender} as boolean)
    WHERE user_student.status IS NOT NULL AND user_prof.status IS NOT NULL AND messages.allocation_tag_id IN (#{ats.join(',')}) AND cast(profiles.types & #{Profile_Type_Class_Responsible} AS boolean) AND NOT cast(user_student.status & #{Message_Filter_Sender} as boolean)

    UNION

    SELECT to_char(log_actions.created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
      CASE
       WHEN description LIKE 'post:%' THEN 'enviou post'
       WHEN description LIKE 'assignment_file:%' THEN 'enviou trabalho'
       WHEN description LIKE 'assignment_webconference:%' THEN 'cadastrou webconferencia em trabalho'
       WHEN description LIKE 'lesson_note:%' THEN 'cadastrou nota de aula'
        WHEN description LIKE 'message:%'
          THEN CASE
              WHEN (description ~ 'message: *([0-9]{1,9})')=TRUE AND log_type=1 AND (SELECT COUNT(DISTINCT user_messages.user_id) FROM user_messages, profiles, allocations WHERE user_messages.user_id = allocations.user_id AND allocations.profile_id = profiles.id
            AND allocations.allocation_tag_id=log_actions.allocation_tag_id AND user_messages.user_id<>#{self.student} AND user_messages.message_id= substring(log_actions.description, 'message: *([0-9]{1,9})')::integer AND cast(profiles.types & #{Profile_Type_Class_Responsible} AS boolean))>0
            THEN 'enviou mensagem a responsável'
              WHEN (description ~ 'message: *([0-9]{1,9})')=TRUE AND log_type=1 AND (SELECT COUNT(DISTINCT user_messages.user_id) FROM user_messages, profiles, allocations WHERE user_messages.user_id = allocations.user_id AND allocations.profile_id = profiles.id
            AND allocations.allocation_tag_id=log_actions.allocation_tag_id AND user_messages.user_id<>#{self.student} AND user_messages.message_id= substring(log_actions.description, 'message: *([0-9]{1,9})')::integer AND cast(profiles.types & #{Profile_Type_Student} AS boolean))>0
            THEN 'enviou mensagem a participante'
            WHEN log_type=2 AND (description ~ 'message: *([0-9]{1,9})')=TRUE AND (description ~ 'read message from responsible')=TRUE THEN 'abriu mensagem de responsável'
            WHEN log_type=2 AND (description ~ 'message: *([0-9]{1,9})')=TRUE AND (description ~ 'read message from other')=TRUE THEN 'abriu mensagem de participante'
          ELSE
          'enviou mensagem'
          END
       WHEN description LIKE 'public_file:%' THEN 'enviou arquivo publico'
      END AS action,
      CASE
        WHEN description LIKE 'public_file:%' THEN (SELECT attachment_file_name FROM public.public_files WHERE id = substring(log_actions.description, 'public_file: *([0-9]{1,9})')::integer)
        WHEN description LIKE 'message:%' THEN (substring(log_actions.description, 'message: *([0-9]{1,9})'))
        WHEN description LIKE 'post:%' THEN (SELECT DISTINCT discussions.name FROM discussion_posts, discussions, academic_allocations
          WHERE discussion_posts.academic_allocation_id = academic_allocations.id AND discussions.id = academic_allocations.academic_tool_id AND academic_tool_type='Discussion' AND discussion_posts.id=substring(log_actions.description, 'post: *([0-9]{1,9})')::integer)
        WHEN description LIKE 'assignment_file:%' THEN (SELECT DISTINCT assignments.name FROM academic_allocations, assignment_files, assignments, academic_allocation_users
          WHERE assignment_files.academic_allocation_user_id = academic_allocation_users.id AND assignments.id = academic_allocations.academic_tool_id AND
            academic_allocation_users.academic_allocation_id = academic_allocations.id AND assignment_files.id=substring(log_actions.description, 'assignment_file: *([0-9]{1,9})')::integer AND academic_allocations.academic_tool_type='Assignment')
        WHEN description LIKE 'assignment_webconference:%' THEN (SELECT DISTINCT assignments.name FROM academic_allocations, assignments, academic_allocation_users, assignment_webconferences
        WHERE assignments.id = academic_allocations.academic_tool_id AND academic_allocation_users.academic_allocation_id = academic_allocations.id AND
          academic_allocation_users.id = assignment_webconferences.academic_allocation_user_id AND academic_allocations.academic_tool_type='Assignment' AND assignment_webconferences.id=substring(log_actions.description, 'assignment_webconference: *([0-9]{1,9})')::integer)
      ELSE ''
      END AS tool,
      CASE
        WHEN description LIKE 'post:%' THEN 'Fórum'
        WHEN description LIKE 'assignment_file:%' THEN 'Trabalho'
        WHEN description LIKE 'assignment_webconference:%' THEN 'Trabalho'
        WHEN description LIKE 'lesson_note:%' THEN 'Aula'
        WHEN description LIKE 'message:%' THEN 'Mensagem'
        WHEN description LIKE 'public_file:%' THEN 'Arquivo Público'
      END AS tool_type,
      ''::text AS info
      FROM
        log_actions
      WHERE (log_actions.user_id = #{self.student} AND (log_type=1 OR (log_type=2 AND description LIKE 'message:%')) AND description NOT LIKE 'allocation:%') AND log_actions.allocation_tag_id IN (#{ats.join(',')})
    ORDER BY datetime;
    SQL
  end

  def get_allocation_tag
    allocation_tag = AllocationTag.find(self.allocation_tag_id).info unless self.allocation_tag_id.blank?
  end

  def self.drop_and_create_table_temporary_logs_navigation_sub(ats, arr_id_student)
    LogAccess.find_by_sql <<-SQL
        DROP TABLE IF EXISTS temp_logs_nav_sub;

        CREATE TEMPORARY TABLE temp_logs_nav_sub AS SELECT to_char(lognsub.created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
        CASE
          WHEN lognsub.assignment_id IS NOT NULL THEN 'acessou atividade'
          WHEN lognsub.discussion_id IS NOT NULL THEN 'acessou fórum'
          WHEN lognsub.chat_room_id IS NOT NULL THEN  'acessou chat'
          WHEN lognsub.group_assignment_id IS NOT NULL THEN 'acessou atividade em grupo'
          WHEN lognsub.exam_id IS NOT NULL THEN 'acessou prova'
          WHEN lognsub.webconference_id IS NOT NULL THEN 'acessou webconferência'
          WHEN lognsub.lesson_id IS NOT NULL THEN 'acessou aula'
          WHEN lognsub.support_material_file IS NOT NULL THEN 'acessou material de apoio'
          WHEN lognsub.bibliography IS NOT NULL THEN 'acessou bilbiografia'
          WHEN lognsub.digital_class_lesson IS NOT NULL THEN 'acessou digital class'
          WHEN lognsub.public_file_name IS NOT NULL THEN 'download de arquivo em área publica'
        END AS action,
        (coalesce((lognsub.public_file_name),'') || coalesce((lognsub.support_material_file),'') || coalesce((discussions.name),'') || coalesce((assignments.name),'') || coalesce((exams.name),'') || coalesce((chat_rooms.title),'')
        || coalesce((chat_historico.title),'') || coalesce((group_assignments.group_name),'')  || coalesce((webconferences.title),'')  ||
        coalesce((CASE lessons.type_lesson WHEN 0 THEN COALESCE(lessons.name, lesson) WHEN 1 THEN COALESCE(lessons.address, lesson) ELSE lesson END),'')) AS tool,
        CASE
          WHEN lognsub.assignment_id IS NOT NULL THEN 'Trabalho'
          WHEN lognsub.discussion_id IS NOT NULL THEN 'Fórum'
          WHEN lognsub.chat_room_id IS NOT NULL THEN  'Chat'
          WHEN lognsub.group_assignment_id IS NOT NULL THEN 'Trabalho'
          WHEN lognsub.exam_id IS NOT NULL THEN 'Prova'
          WHEN lognsub.webconference_id IS NOT NULL THEN 'Webconferência'
          WHEN lognsub.lesson_id IS NOT NULL THEN 'Aula'
          WHEN lognsub.support_material_file IS NOT NULL THEN 'Material de apoio'
          WHEN lognsub.bibliography IS NOT NULL THEN 'Bibliografia'
          WHEN lognsub.digital_class_lesson IS NOT NULL THEN 'Digital Class'
          WHEN lognsub.public_file_name IS NOT NULL THEN 'Área Pública'
        END AS tool_type,
        log_navigations.user_id,
        ''::text AS info
        FROM log_navigation_subs AS lognsub LEFT JOIN log_navigations ON log_navigations.id = log_navigation_id LEFT JOIN  assignments ON lognsub.assignment_id = assignments.id
               LEFT JOIN chat_rooms ON lognsub.chat_room_id = chat_rooms.id LEFT JOIN chat_rooms as chat_historico ON lognsub.hist_chat_room_id = chat_historico.id LEFT JOIN group_assignments ON
               lognsub.group_assignment_id = group_assignments.id LEFT JOIN lessons ON lognsub.lesson_id = lessons.id LEFT JOIN discussions ON lognsub.discussion_id = discussions.id LEFT JOIN exams
               ON exams.id = lognsub.exam_id LEFT JOIN webconferences ON lognsub.webconference_id = webconferences.id WHERE log_navigations.allocation_tag_id IN (#{ats.join(',')}) AND
               log_navigations.user_id IN (#{arr_id_student.join(',')}) AND (
        lognsub.assignment_id IS NOT NULL OR lognsub.discussion_id IS NOT NULL OR lognsub.chat_room_id IS NOT NULL OR lognsub.group_assignment_id IS NOT NULL OR lognsub.exam_id IS NOT NULL OR
        lognsub.webconference_id IS NOT NULL OR lognsub.lesson_id IS NOT NULL OR lognsub.support_material_file IS NOT NULL OR lognsub.digital_class_lesson IS NOT NULL OR lognsub.public_file_name IS NOT NULL)
    SQL
  end

  def self.drop_and_create_table_temporary_logs_chat_messages(ats, arr_id_student)
    LogAccess.find_by_sql <<-SQL
        DROP TABLE IF EXISTS temp_logs_chat_messages;

        CREATE TEMPORARY TABLE temp_logs_chat_messages AS SELECT to_char(chat_messages.created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
        'enviou mensagem no chat'::text AS action,
        chat_rooms.title AS tool,
        academic_allocations.academic_tool_type AS tool_type,
        allocations.user_id,
        ''::text AS info
        FROM chat_messages, academic_allocations, allocations, chat_rooms
        WHERE chat_rooms.id = academic_allocations.academic_tool_id AND
          chat_messages.academic_allocation_id = academic_allocations.id AND academic_allocations.academic_tool_type = 'ChatRoom' AND
          allocations.id = chat_messages.allocation_id AND allocations.user_id IN (#{arr_id_student.join(',')}) AND
        allocations.allocation_tag_id IN (#{ats.join(',')})
    SQL
  end

  def self.drop_and_create_table_temporary_logs_navigation(ats, arr_id_student)
    LogAccess.find_by_sql <<-SQL
        DROP TABLE IF EXISTS temp_logs_navigation;

        CREATE TEMPORARY TABLE temp_logs_navigation AS SELECT to_char(created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
        CASE
          WHEN menus.name = 'menu_portfolio' THEN 'Trabalho'
          WHEN menus.name = 'menu_discussion' THEN 'Fórum'
          WHEN menus.name = 'menu_chat' THEN 'Chat'
          WHEN menus.name = 'menu_exam' THEN 'Prova'
          WHEN menus.name = 'menu_webconference' THEN 'Webconferência'
          WHEN menus.name = 'menu_lesson' THEN 'Aula'
          WHEN menus.name = 'menu_support_material' THEN 'Material de apoio'
          WHEN menus.name = 'menu_bibliography' THEN 'Bibliografia'
          WHEN menus.name = 'menu_agenda' THEN 'Agenda'
          WHEN menus.name = 'menu_dc_lesson' THEN 'Digital Class'
          WHEN menus.name = 'menu_participants' THEN 'Participantes'
          WHEN menus.name = 'menu_score_student' THEN 'Acompanhamento'
          WHEN menus.name = 'menu_messages' THEN 'Mensagem'
        END AS tool_type,
        resources.description AS action, ''::text AS tool, log_navigations.user_id, ''::text AS info
      FROM log_navigations LEFT JOIN menus ON log_navigations.menu_id = menus.id LEFT JOIN resources ON resources.id = menus.resource_id WHERE menus.name IS NOT NULL AND log_navigations.allocation_tag_id IN (#{ats.join(',')}) AND
      log_navigations.user_id IN (#{arr_id_student.join(',')})
    SQL
  end

   def self.drop_and_create_table_temporary_logs_access(ats, arr_id_student)
    LogAccess.find_by_sql <<-SQL
        DROP TABLE IF EXISTS temp_logs_access;

        CREATE TEMPORARY TABLE temp_logs_access AS SELECT to_char(created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime, CASE WHEN log_type=1 THEN 'acessou o Solar' ELSE 'acessou turma' END AS action,  ''::text AS tool, ''::text AS tool_type, log_accesses.user_id
      FROM log_accesses WHERE log_accesses.user_id IN (#{arr_id_student.join(',')}) AND (allocation_tag_id IS NULL OR log_accesses.allocation_tag_id IN (#{ats.join(',')}))
    SQL
  end

  def self.drop_and_create_table_temporary_logs_comments(ats, arr_id_student)
    LogAccess.find_by_sql <<-SQL
        DROP TABLE IF EXISTS temp_logs_comments;

        CREATE TEMPORARY TABLE temp_logs_comments AS SELECT to_char(comments.updated_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
          CASE
          WHEN academic_allocations.academic_tool_type='Assignment'
            THEN 'recebeu comentário em trabalho'
          WHEN academic_allocations.academic_tool_type='Discussion'
            THEN 'recebeu comentário em Fórum'
          WHEN academic_allocations.academic_tool_type='ChatRoom'
            THEN 'recebeu comentário no chat'
          WHEN academic_allocations.academic_tool_type='Webconference'
            THEN 'recebeu comentário em webconferencia'
         END AS action,
         CASE
          WHEN academic_allocations.academic_tool_type='Assignment'
            THEN (SELECT name FROM assignments WHERE id= academic_allocations.academic_tool_id)
          WHEN academic_allocations.academic_tool_type='Discussion'
            THEN (SELECT name FROM discussions WHERE id= academic_allocations.academic_tool_id)
                WHEN academic_allocations.academic_tool_type='ChatRoom'
            THEN (SELECT title FROM chat_rooms WHERE id= academic_allocations.academic_tool_id)
          WHEN academic_allocations.academic_tool_type='Webconference'
            THEN (SELECT title FROM webconferences WHERE id= academic_allocations.academic_tool_id)
         END AS tool,
         academic_allocations.academic_tool_type AS tool_type,
         academic_allocation_users.user_id AS user_id,
         group_participants.user_id AS group_user_id,
         ''::text AS info
        FROM comments, academic_allocation_users LEFT JOIN academic_allocations ON academic_allocation_users.academic_allocation_id = academic_allocations.id
          LEFT JOIN  group_participants ON academic_allocation_users.group_assignment_id = group_participants.group_assignment_id
        WHERE comments.academic_allocation_user_id = academic_allocation_users.id AND (academic_allocation_users.user_id IN (#{arr_id_student.join(',')}) OR group_participants.user_id IN (#{arr_id_student.join(',')})) AND academic_allocations.allocation_tag_id IN (#{ats.join(',')})
    SQL
  end

end