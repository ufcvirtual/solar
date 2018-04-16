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
    SELECT to_char(lognsub.created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
      CASE 
        WHEN lognsub.assignment_id IS NOT NULL THEN 'acessou atividade'
        WHEN lognsub.discussion_id IS NOT NULL THEN 'acessou fórun'
        WHEN lognsub.chat_room_id IS NOT NULL THEN  'acessou chat'
        WHEN lognsub.group_assignment_id IS NOT NULL THEN 'acessou atividade em grupo'
        WHEN lognsub.exam_id IS NOT NULL THEN 'acessou prova'
        WHEN lognsub.webconference_id IS NOT NULL THEN 'acessou webconferencia'
        WHEN lognsub.lesson_id IS NOT NULL THEN 'acessou aula'
        WHEN lognsub.support_material_file IS NOT NULL THEN 'acessou material de apoio'
        WHEN lognsub.bibliography IS NOT NULL THEN 'acessou bilbiografia'
        WHEN lognsub.digital_class_lesson IS NOT NULL THEN 'acessou digital class'
      END AS action,
      (coalesce((support_material_file),'') || coalesce((discussions.name),'') || coalesce((assignments.name),'') || coalesce((exams.name),'') || coalesce((chat_rooms.title),'')
      || coalesce((chat_historico.title),'') || coalesce((group_assignments.group_name),'')  || coalesce((webconferences.title),'')  || 
      coalesce((CASE lessons.type_lesson WHEN 0 THEN COALESCE(lessons.name, lesson) WHEN 1 THEN COALESCE(lessons.address, lesson) ELSE lesson END),'')) AS tool,
      CASE 
        WHEN lognsub.assignment_id IS NOT NULL THEN 'Assignment'
        WHEN lognsub.discussion_id IS NOT NULL THEN 'Discussion'
        WHEN lognsub.chat_room_id IS NOT NULL THEN  'ChatRoom'
        WHEN lognsub.group_assignment_id IS NOT NULL THEN 'Assignment'
        WHEN lognsub.exam_id IS NOT NULL THEN 'Exam'
        WHEN lognsub.webconference_id IS NOT NULL THEN 'Webconference'
        WHEN lognsub.lesson_id IS NOT NULL THEN 'Lesson'
        WHEN lognsub.support_material_file IS NOT NULL THEN '"SupportMaterialFile"'
        WHEN lognsub.bibliography IS NOT NULL THEN 'Bibliography'
        WHEN lognsub.digital_class_lesson IS NOT NULL THEN 'Digitalclass'
      END AS tool_type 
    FROM log_navigation_subs AS lognsub LEFT JOIN log_navigations ON log_navigations.id = log_navigation_id LEFT JOIN  assignments ON lognsub.assignment_id = assignments.id
           LEFT JOIN chat_rooms ON lognsub.chat_room_id = chat_rooms.id LEFT JOIN chat_rooms as chat_historico ON lognsub.hist_chat_room_id = chat_historico.id LEFT JOIN group_assignments ON 
           lognsub.group_assignment_id = group_assignments.id LEFT JOIN lessons ON lognsub.lesson_id = lessons.id LEFT JOIN discussions ON lognsub.discussion_id = discussions.id LEFT JOIN exams 
           ON exams.id = lognsub.exam_id LEFT JOIN webconferences ON lognsub.webconference_id = webconferences.id WHERE log_navigations.allocation_tag_id IN (#{ats.join(',')}) AND
           (log_navigations.user_id = #{self.student}) AND (
    lognsub.assignment_id IS NOT NULL OR lognsub.discussion_id IS NOT NULL OR lognsub.chat_room_id IS NOT NULL OR lognsub.group_assignment_id IS NOT NULL OR lognsub.exam_id IS NOT NULL OR
    lognsub.webconference_id IS NOT NULL OR lognsub.lesson_id IS NOT NULL OR lognsub.support_material_file IS NOT NULL OR lognsub.digital_class_lesson IS NOT NULL)
    UNION
    SELECT to_char(created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime, menus.name AS action, '' AS tool, '' AS tool_type
    FROM log_navigations LEFT JOIN menus ON log_navigations.menu_id = menus.id WHERE menus.name IS NOT NULL AND log_navigations.allocation_tag_id IN (#{ats.join(',')}) AND
             (log_navigations.user_id = #{self.student})
    UNION
    SELECT to_char(comments.updated_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
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
     academic_allocations.academic_tool_type AS tool_type
    FROM comments, academic_allocation_users LEFT JOIN academic_allocations ON academic_allocation_users.academic_allocation_id = academic_allocations.id
      LEFT JOIN  group_participants ON academic_allocation_users.group_assignment_id = group_participants.group_assignment_id
    WHERE comments.academic_allocation_user_id = academic_allocation_users.id AND (academic_allocation_users.user_id=#{self.student} OR group_participants.user_id=#{self.student}) AND academic_allocations.allocation_tag_id IN (#{ats.join(',')})
    UNION
    SELECT to_char(created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime, CASE WHEN log_type=1 THEN 'acessou o Solar' ELSE 'acessou turma' END AS action,  '' AS tool, '' AS tool_type
      FROM log_accesses WHERE log_accesses.user_id = #{self.student} AND (allocation_tag_id IS NULL OR log_accesses.allocation_tag_id IN (#{ats.join(',')}))
    UNION
    SELECT to_char(log_actions.created_at,'dd/mm/YYYY HH24:MI:SS') AS datetime,
      CASE 
       WHEN description LIKE 'post:%' THEN 'enviou post'
       WHEN description LIKE 'assignment_file:%' THEN 'enviou trabalho'
       WHEN description LIKE 'assignment_webconference:%' THEN 'cadastrou webconferencia em trabalho'
       WHEN description LIKE 'lesson_note:%' THEN 'cadastrou nota de aula'
        WHEN description LIKE 'message:%' 
          THEN CASE 
              WHEN (description ~ 'message: *([0-9]{1,9})')=TRUE AND (SELECT COUNT(DISTINCT user_messages.user_id) FROM user_messages, profiles, allocations WHERE user_messages.user_id = allocations.user_id AND allocations.profile_id = profiles.id 
            AND allocations.allocation_tag_id=log_actions.allocation_tag_id AND user_messages.user_id<>#{self.student} AND user_messages.message_id= substring(log_actions.description, 'message: *([0-9]{1,9})')::integer AND cast(profiles.types & #{Profile_Type_Class_Responsible} AS boolean))>0
            THEN 'enviou mensagem a responsável'
              WHEN (description ~ 'message: *([0-9]{1,9})')=TRUE AND (SELECT COUNT(DISTINCT user_messages.user_id) FROM user_messages, profiles, allocations WHERE user_messages.user_id = allocations.user_id AND allocations.profile_id = profiles.id 
            AND allocations.allocation_tag_id=log_actions.allocation_tag_id AND user_messages.user_id<>#{self.student} AND user_messages.message_id= substring(log_actions.description, 'message: *([0-9]{1,9})')::integer AND cast(profiles.types & #{Profile_Type_Student} AS boolean))>0
            THEN 'enviou mensagem a colega'
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
        WHEN description LIKE 'post:%' THEN 'Discussion'
        WHEN description LIKE 'assignment_file:%' THEN 'Assignment'
        WHEN description LIKE 'assignment_webconference:%' THEN 'Assignment'
        WHEN description LIKE 'lesson_note:%' THEN 'Lesson'
        WHEN description LIKE 'message:%' THEN 'Message'
        WHEN description LIKE 'public_file:%' THEN 'Public_file'
      END AS tool_type 
    FROM 
      log_actions
    WHERE (log_actions.user_id = #{self.student} AND log_type=1 AND description NOT LIKE 'allocation:%') AND log_actions.allocation_tag_id IN (#{ats.join(',')})
    ORDER BY datetime;
    SQL
  end

  def get_allocation_tag
    allocation_tag = AllocationTag.find(self.allocation_tag_id).info unless self.allocation_tag_id.blank?
  end 

end
