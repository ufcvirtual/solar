module V1::Contents

  def copy_posts(from_posts, to_at, parent_id=nil)
    from_posts.each do |from_post|
      to_ac    = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Discussion", academic_tool_id: from_post.academic_allocation.academic_tool_id).first
      new_post = copy_object(from_post, {"academic_allocation_id" => to_ac.id, "parent_id" => parent_id})
      copy_objects(from_post.files, {"discussion_post_id" => new_post.id}, true)
      copy_posts(from_post.children, to_at, new_post.try(:id))
    end
  end

  def copy_sent_assignments(from_sent_assignments, to_at)
    from_sent_assignments.each do |from_sent_assignment|
      to_ac      = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Assignment", academic_tool_id: from_sent_assignment.academic_allocation.academic_tool_id).first
      attributes = from_sent_assignment.attributes.except("id", "grade").merge("academic_allocation_id" => to_ac.id)

      unless from_sent_assignment.group_assignment_id.nil?
        new_group  = copy_object(from_sent_assignment.group_assignment, {"academic_allocation_id" => to_ac}, false, :group_participants)
        attributes.merge!("group_assignment_id" => new_group.id)
      end

      new_sa = SentAssignment.where(attributes).first_or_create do |sa|
        sa.grade = from_sent_assignment.grade # updates grade with most recent copied group
      end

      copy_objects(from_sent_assignment.assignment_comments, {"sent_assignment_id" => new_sa.id}, true, :files)
      copy_objects(from_sent_assignment.assignment_files, {"sent_assignment_id" => new_sa.id}, true)
    end
  end

  def copy_group_assignments(from_group_assignments, to_at)
    from_group_assignments.each do |from_group_assignment|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Assignment", academic_tool_id: from_group_assignment.academic_allocation.academic_tool_id).first
      copy_object(from_group_assignment, {"academic_allocation_id" => to_ac}, false, :group_participants)
    end
  end

  def replicate_content(from_group, to_group, merge = true)
    raise ActiveRecord::RecordNotFound if from_group.nil? or to_group.nil?
    from_ats, to_at = ((from_group.offer_id == to_group.offer_id) ? [from_group.allocation_tag.id] : from_group.allocation_tag.related), to_group.allocation_tag.id
    from_academic_allocations = AcademicAllocation.where(allocation_tag_id: from_ats) # recover all from group which will be copied


    ActiveRecord::Base.transaction do
      remove_all_content(to_at) unless merge

      replicate_discussions(from_academic_allocations, to_at)
      replicate_chats(from_academic_allocations, to_at)
      replicate_assignments(from_academic_allocations, to_at)

      from_ats.each do |from_at|
        replicate_messages(from_at, to_at)
        replicate_public_files(from_at, to_at)
      end

      main_group, secundary_group = merge ? [to_group, from_group] : [from_group, to_group]
      Merge.create! main_group_id: main_group.id, secundary_group_id: secundary_group.id, type_merge: merge
      LogAction.create(log_type: LogAction::TYPE[:create], user_id: 0, ip: env['REMOTE_ADDR'], description: "merge: transfering content from #{from_group.allocation_tag.info} to #{to_group.allocation_tag.info}, merge type: #{merge}") rescue nil
    end
  end

  # remove posts, sent_assignments, group_assignments, chat_messages and dependents
  def remove_all_content(allocation_tag)
    AcademicAllocation.where(academic_tool_type: "Discussion", allocation_tag_id: allocation_tag).map{ |ac| ac.discussion_posts.delete_all }
    AcademicAllocation.where(academic_tool_type: "Assignment", allocation_tag_id: allocation_tag).map{ |ac|
      ac.sent_assignments.map(&:delete_with_dependents)
      ac.group_assignments.map(&:delete_with_dependents)
    }
    AcademicAllocation.where(academic_tool_type: "ChatRoom", allocation_tag_id: allocation_tag).map{ |ac| ac.chat_messages.delete_all }
  end

  def copy_file(file_to_copy_path, file_copied_path)
    unless File.exists? file_copied_path or not(File.exists? file_to_copy_path)
      file = File.new file_copied_path, "w"
      FileUtils.cp file_to_copy_path, file # copy file content to new file
    end
  end

  def copy_objects(objects_to_copy, merge_attributes={}, is_file = false, nested = nil)
    objects_to_copy.each do |object_to_copy|
      copy_object(object_to_copy, merge_attributes, is_file, nested)
    end
  end

  def copy_object(object_to_copy, merge_attributes={}, is_file = false, nested = nil)
    new_object = object_to_copy.class.where(object_to_copy.attributes.except("id").merge(merge_attributes)).first_or_initialize
    new_object.merge = true if new_object.respond_to?(:merge) # used so call save without callbacks (before_save, before_create)
    new_object.save
    copy_file(object_to_copy.attachment.path, new_object.attachment.path) if is_file and object_to_copy.respond_to? :attachment
    copy_objects(object_to_copy.send(nested.to_sym), {"#{new_object.class.to_s.tableize.singularize}_id" => new_object.id}, is_file) unless nested.nil?

    new_object
  end

  # if there is any tool at group which data are being copied that don't exist at the receiving data group, copy it
  def create_missing_tools(from_acs_tools, to_at, type)
    to_acs_tools = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_id: from_acs_tools, academic_tool_type: type).pluck(:academic_tool_id)

    (from_acs_tools - to_acs_tools).each do |missing_tool_id|
      AcademicAllocation.create(allocation_tag_id: to_at, academic_tool_type: type, academic_tool_id: missing_tool_id)
    end
  end

  def replicate_discussions(from_academic_allocations, to_at)
    from_discussions_academic_allocations = from_academic_allocations.where(academic_tool_type: "Discussion")
    create_missing_tools(from_discussions_academic_allocations.pluck(:academic_tool_id), to_at, "Discussion")

    from_posts = Post.where(parent_id: nil, academic_allocation_id: from_discussions_academic_allocations.pluck(:id))
    copy_posts(from_posts, to_at)
  end

  def replicate_chats(from_academic_allocations, to_at)
    from_chats_academic_allocations = from_academic_allocations.where(academic_tool_type: "ChatRoom")
    create_missing_tools(from_chats_academic_allocations.pluck(:academic_tool_id), to_at, "ChatRoom")

    ChatRoom.where(id: from_chats_academic_allocations.pluck(:academic_tool_id)).each do |chat|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "ChatRoom", academic_tool_id: chat.id).first

      copy_objects(chat.messages, {"academic_allocation_id" => to_ac.id})
      copy_objects(chat.participants, {"academic_allocation_id" => to_ac.id})
    end
  end

  def replicate_assignments(from_academic_allocations, to_at)
    from_assignments_academic_allocations = from_academic_allocations.where(academic_tool_type: "Assignment")
    create_missing_tools(from_assignments_academic_allocations.pluck(:academic_tool_id), to_at, "Assignment")

    ac_ids = from_assignments_academic_allocations.pluck(:id)

    copy_sent_assignments(SentAssignment.where(academic_allocation_id: ac_ids), to_at) # copy all sent assignments and dependents
    copy_group_assignments(GroupAssignment.where(academic_allocation_id: ac_ids), to_at) # copy all group_assignments (if already doesn't exist) and participants
  end

  def replicate_messages(from_at, to_at)
    from_messages_academic_allocations = Message.where(allocation_tag_id: from_at) # recupera todas as mensagens da turma a repassar dados

    from_messages_academic_allocations.each do |from_message|
      new_message = copy_object(from_message, {"allocation_tag_id" => to_at})
      copy_objects(from_message.user_messages, {"message_id" => new_message.id}, false, :user_message_labels)
      copy_objects(from_message.files, {"message_id" => new_message.id}, true)
    end
  end

  def replicate_public_files(from_at, to_at)
    copy_objects(PublicFile.where(allocation_tag_id: from_at), {"allocation_tag_id" => to_at}, true)
  end

end
