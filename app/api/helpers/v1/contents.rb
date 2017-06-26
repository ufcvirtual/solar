module V1::Contents

  def copy_posts(from_posts, to_at, parent_id=nil)
    from_posts.each do |from_post|
      to_ac    = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Discussion', academic_tool_id: from_post.academic_allocation.academic_tool_id).first
      new_post = copy_object(from_post, {'academic_allocation_id' => to_ac.id, 'parent_id' => parent_id}, false, nil, {}, true)
      copy_objects(from_post.files, {'discussion_post_id' => new_post.id}, true)
      copy_posts(from_post.children, to_at, new_post.try(:id))
    end
  end

  def get_acu(ac_id, from_acu, user_id, group_id=nil)
    unless from_acu.nil?
      new_acu = AcademicAllocationUser.where(academic_allocation_id: ac_id, user_id: user_id, group_assignment_id: group_id).first_or_initialize
      # if new_acu.new_record? || from_acu.updated_at.nil? || new_acu.updated_at.nil? || (from_acu.updated_at.to_time > new_acu.updated_at.to_time)
        new_acu.grade = from_acu.grade # updates grade with most recent copied group
        new_acu.working_hours = from_acu.working_hours
        new_acu.status = from_acu.status
        new_acu.new_after_evaluation = from_acu.new_after_evaluation
        new_acu.merge = true
        new_acu.save
      # end
      new_acu.id
     end
  end

  def copy_academic_allocation_users(from_academic_allocation_users, to_at)
    from_academic_allocation_users.each do |from_academic_allocation_user|
      to_ac      = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Assignment', academic_tool_id: from_academic_allocation_user.academic_allocation.academic_tool_id).first
      attributes = from_academic_allocation_user.attributes.except('id', 'grade', 'working_hours', 'status', 'new_after_evaluation', 'created_at', 'updated_at').merge('academic_allocation_id' => to_ac.id)
      unless from_academic_allocation_user.group_assignment_id.blank?
        new_group  = copy_object(GroupAssignment.find(from_academic_allocation_user.group_assignment_id), {'academic_allocation_id' => to_ac.id}, false, :group_participants)
        attributes.merge!('group_assignment_id' => new_group.id)
      end
      new_acu = get_acu(to_ac.id, from_academic_allocation_user, from_academic_allocation_user.user_id, new_group.try(:id))

      copy_objects(from_academic_allocation_user.assignment_comments, { 'academic_allocation_user_id' => new_acu }, true, :files)
      copy_objects(from_academic_allocation_user.assignment_files, { 'academic_allocation_user_id' => new_acu }, true)
      copy_objects(from_academic_allocation_user.assignment_webconferences, { 'academic_allocation_user_id' => new_acu }, true, nil, { to: :set_origin, from: :id })
    end
  end

  def copy_group_assignments(from_group_assignments, to_at)
    from_group_assignments.each do |from_group_assignment|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Assignment', academic_tool_id: from_group_assignment.academic_allocation.academic_tool_id).first
      copy_object(from_group_assignment, { 'academic_allocation_id' => to_ac }, false, :group_participants)
    end
  end

  def replicate_content(from_group, to_group, merge = true)
    raise ActiveRecord::RecordNotFound if from_group.nil? || to_group.nil?
    from_ats, to_at = ((from_group.offer_id == to_group.offer_id) ? [from_group.allocation_tag.id] : from_group.allocation_tag.related), to_group.allocation_tag.id
    from_academic_allocations = AcademicAllocation.where(allocation_tag_id: from_ats) # recover all from group which will be copied
    main_group, secundary_group = merge ? [to_group, from_group] : [from_group, to_group]

    ActiveRecord::Base.transaction do
      # cant unmerge if never merged
      raise 'not merged' if !merge && !Merge.where(main_group_id: main_group.id, secundary_group_id: secundary_group.id).last.try(:type_merge)
      
      remove_all_content(to_at) unless merge

      replicate_discussions(from_academic_allocations, to_at)
      replicate_chats(from_academic_allocations, to_at)
      replicate_assignments(from_academic_allocations, to_at)
      replicate_webconferences(from_academic_allocations, to_at, from_group.allocation_tag.id)
      replicate_exams(from_academic_allocations, to_at)
      replicate_schedule_events(from_academic_allocations, from_group.allocation_tag.id, to_at)
      
      from_ats.each do |from_at|
        replicate_messages(from_at, to_at)
        replicate_public_files(from_at, to_at)
      end

      Merge.create! main_group_id: main_group.id, secundary_group_id: secundary_group.id, type_merge: merge
      LogAction.create(log_type: LogAction::TYPE[:create], user_id: 0, ip: request.headers['HTTP_CLIENT_IP'], description: "merge: transfering content from #{from_group.allocation_tag.info} to #{to_group.allocation_tag.info}, merge type: #{merge}") rescue nil
    end

  end

  # remove posts, academic_allocation_users, group_assignments, chat_messages and dependents
  def remove_all_content(allocation_tag)
    AcademicAllocation.where(academic_tool_type: 'Discussion', allocation_tag_id: allocation_tag).map{ |ac| ac.discussion_posts.map(&:delete_with_dependents) }
    AcademicAllocation.where(academic_tool_type: 'Assignment', allocation_tag_id: allocation_tag).map{ |ac|
      ac.academic_allocation_users.map do |acu|
        acu.merge = true
        acu.delete_with_dependents
      end
      ac.group_assignments.map(&:delete_with_dependents)
    }
    AcademicAllocation.where(academic_tool_type: 'ChatRoom', allocation_tag_id: allocation_tag).map{ |ac| 
      ac.academic_allocation_users.map(&:delete_with_dependents)
      ac.chat_messages.delete_all 
    }
    AcademicAllocation.where(academic_tool_type: 'Webconference', allocation_tag_id: allocation_tag).map{ |ac| 
      ac.academic_allocation_users.map(&:delete_with_dependents)
      LogAction.where(academic_allocation_id: ac.id, log_type: 7).delete_all
    }
    AcademicAllocation.where(academic_tool_type: 'Exam', allocation_tag_id: allocation_tag).map{ |exam|
      exam.academic_allocation_users.map(&:delete_with_dependents)
    }
  AcademicAllocationUser.joins(:academic_allocation).where(academic_allocations: {allocation_tag_id: allocation_tag}).map(&:delete_with_dependents)
  end

  def copy_file(file_to_copy_path, file_copied_path)
    unless File.exists? file_copied_path || !(File.exists? file_to_copy_path)
      file = File.new file_copied_path, 'w'
      FileUtils.cp file_to_copy_path, file # copy file content to new file
    end
  end

  def copy_objects(objects_to_copy, merge_attributes={}, is_file = false, nested = nil, call_methods = {}, acu = false)
    objects_to_copy.each do |object_to_copy|
      copy_object(object_to_copy, merge_attributes, is_file, nested, call_methods, acu)
    end
  end

  def copy_object(object_to_copy, merge_attributes={}, is_file = false, nested = nil, call_methods = {}, acu=false)
    new_object = object_to_copy.class.where(object_to_copy.attributes.except('id', 'children_count', 'updated_at', 'new_after_evaluation', 'academic_allocation_user_id', 'created_at').merge!(merge_attributes)).first_or_initialize

    new_object.created_at = object_to_copy.created_at if object_to_copy.respond_to?(:created_at)
    new_object.updated_at = object_to_copy.updated_at if object_to_copy.respond_to?(:updated_at)
    new_object.merge = true if new_object.respond_to?(:merge) # used so call save without callbacks (before_save, before_create)

    if acu
      new_object.academic_allocation_user_id = get_acu(new_object.academic_allocation.id, object_to_copy.academic_allocation_user, (object_to_copy.user_id || object_to_copy.allocation.user_id)) #rescue nil
    end

    new_object.send(call_methods[:to], object_to_copy.send(call_methods[:from])) unless call_methods.empty?
    new_object.save

    copy_file(object_to_copy.attachment.path, new_object.attachment.path) if is_file && object_to_copy.respond_to?(:attachment)
    copy_objects(object_to_copy.send(nested.to_sym), {"#{new_object.class.to_s.tableize.singularize}_id" => new_object.id}, is_file) unless nested.nil?

    new_object
  end

  # if there is any tool at group which data are being copied that don't exist at the receiving data group, copy it
  def create_missing_tools(from_acs_tools, to_at, type, call_method = nil, from_at = nil)
    to_acs_tools = call_method.nil? ? AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_id: from_acs_tools, academic_tool_type: type).pluck(:academic_tool_id).uniq : []

    (from_acs_tools - to_acs_tools).each do |missing_tool_id|
      if call_method.nil?
        AcademicAllocation.create(allocation_tag_id: to_at, academic_tool_type: type, academic_tool_id: missing_tool_id)
      else
        type.constantize.find(missing_tool_id).send(call_method, to_at, from_at)
      end
    end
  end

  def replicate_discussions(from_academic_allocations, to_at)
    from_discussions_academic_allocations = from_academic_allocations.where(academic_tool_type: 'Discussion')
    create_missing_tools(from_discussions_academic_allocations.pluck(:academic_tool_id), to_at, 'Discussion')

    from_posts = Post.where(parent_id: nil, academic_allocation_id: from_discussions_academic_allocations.pluck(:id))
    copy_posts(from_posts, to_at)
  end

  def replicate_chats(from_academic_allocations, to_at)
    from_chats_academic_allocations = from_academic_allocations.where(academic_tool_type: 'ChatRoom')
    create_missing_tools(from_chats_academic_allocations.pluck(:academic_tool_id), to_at, 'ChatRoom')

    from_chats_academic_allocations.each do |chat|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'ChatRoom', academic_tool_id: chat.academic_tool_id).first

      copy_objects(chat.chat_messages, {"academic_allocation_id" => to_ac.id}, false, nil, {}, true)
      copy_objects(chat.chat_participants, {"academic_allocation_id" => to_ac.id})
    end
  end

  def replicate_assignments(from_academic_allocations, to_at)
    from_assignments_academic_allocations = from_academic_allocations.where(academic_tool_type: 'Assignment')
    create_missing_tools(from_assignments_academic_allocations.pluck(:academic_tool_id), to_at, 'Assignment')

    ac_ids = from_assignments_academic_allocations.pluck(:id)

    copy_group_assignments(GroupAssignment.where(academic_allocation_id: ac_ids), to_at) # copy all group_assignments (if already doesn't exist) and participants
    copy_academic_allocation_users(AcademicAllocationUser.where(academic_allocation_id: ac_ids), to_at) # copy all sent assignments and dependents
  end
  
  def replicate_webconferences(from_academic_allocations, to_at, from_at)
    from_webconferences_academic_allocations = from_academic_allocations.where(academic_tool_type: 'Webconference')
    create_missing_tools(from_webconferences_academic_allocations.pluck(:academic_tool_id).uniq, to_at, 'Webconference', :create_copy, from_at)
    from_webconferences_academic_allocations.each do |web|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Webconference', academic_tool_id: web.academic_tool_id).first

      unless to_ac.nil?
        copy_objects(LogAction.where(academic_allocation_id: web.id, log_type: 7), {"academic_allocation_id" => to_ac.id}, false, nil, {}, true)
      end
    end
  end

  def replicate_messages(from_at, to_at)
    from_messages_academic_allocations = Message.where(allocation_tag_id: from_at) # recupera todas as mensagens da turma a repassar dados

    from_messages_academic_allocations.each do |from_message|
      new_message = copy_object(from_message, { 'allocation_tag_id' => to_at })
      copy_objects(from_message.user_messages, { 'message_id' => new_message.id }, false, :user_message_labels)
      copy_objects(from_message.files, { 'message_id' => new_message.id }, true)
    end
  end

  def replicate_public_files(from_at, to_at)
    copy_objects(PublicFile.where(allocation_tag_id: from_at), {'allocation_tag_id' => to_at}, true)
  end

  def replicate_exams(from_academic_allocations, to_at)
    from_exams_academic_allocations = from_academic_allocations.where(academic_tool_type: 'Exam')
    create_missing_tools(from_exams_academic_allocations.pluck(:academic_tool_id), to_at, 'Exam')

    AcademicAllocationUser.where(academic_allocation_id: from_exams_academic_allocations).each do |from_acu|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Exam', academic_tool_id: from_acu.academic_allocation.academic_tool_id).first
      
      new_acu = get_acu(to_ac.id, from_acu, from_acu.user_id, nil)
      AcademicAllocationUser.find(new_acu).copy_dependencies_from(from_acu)
    end
  end

  def get_related_acs(from_acs, from_at, to_at)
    all = []
    from_acs.each do |from_ac|
      ac = AcademicAllocation.where(academic_tool_type: from_ac.academic_tool_type, academic_tool_id: from_ac.academic_tool_id, allocation_tag_id: to_at).first

      if ac.nil?
        event = from_ac.academic_tool_type.constantize.find(from_ac.academic_tool_id)
        acs = AcademicAllocation.where(academic_tool_type: from_ac.academic_tool_type, allocation_tag_id: to_at)

        ac_name_and_date = acs.joins("JOIN schedule_events ON schedule_events.id = academic_allocations.academic_tool_id AND academic_tool_type = 'ScheduleEvent'").joins('JOIN schedules ON schedules.id = schedule_events.schedule_id').where(schedule_events: {title: event.title, type_event: event.type_event}, schedules: {start_date: event.schedule.start_date} ).first

        if ac_name_and_date.nil?
          ac_name = acs.joins("JOIN schedule_events ON schedule_events.id = academic_allocations.academic_tool_id AND academic_tool_type = 'ScheduleEvent'").where(schedule_events: {title: event.title, type_event: event.type_event}).first
          if ac_name.nil?
            new_ac = AcademicAllocation.create(allocation_tag_id: to_at, academic_tool_type: from_ac.academic_tool_type, academic_tool_id: from_ac.academic_tool_id)
            all << {from_ac.id.to_s => new_ac.id}  
          else
            all << {from_ac.id.to_s => ac_name.id}  
          end
        else
          all << {from_ac.id.to_s => ac_name_and_date.id}
        end
      else
         all << {from_ac.id.to_s => ac.id}
      end
    end
    all
  end

  def replicate_schedule_events(from_academic_allocations, from_at, to_at)
    all_acs_related = get_related_acs(from_academic_allocations.where(academic_tool_type: 'ScheduleEvent').joins(:academic_allocation_users), from_at, to_at)

    all_acs_related.each do |acs|
      acs.each do |ac_from, ac_to|
        AcademicAllocationUser.where(academic_allocation_id: ac_from.to_i).each do |acu_from|
          acu = AcademicAllocationUser.where(academic_allocation_id: ac_to.to_i, user_id: acu_from.user_id).first_or_initialize
          acu.attributes = acu_from.attributes.except('id','academic_allocation_id')
          acu.merge = true
          acu.save
        end
      end
    end
  end


end
