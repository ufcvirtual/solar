module V1::V1Helpers

  ## only webserver can access
  def verify_ip_access!
    raise ActiveRecord::RecordNotFound unless YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(request.env['REMOTE_ADDR'])
  end

  def verify_or_create_user(cpf)
    user = User.find_by_cpf(cpf.delete('.').delete('-'))
    return user if user

    user = User.new cpf: cpf
    user.connect_and_validates_user

    raise ActiveRecord::RecordNotFound unless user.valid? and not(user.new_record?)

    user
  end

  def allocate_professors(group, cpfs)
    group.allocations.where(profile_id: 17).update_all(status: 2) # cancel all previous allocations

    cpfs.each do |cpf|
      professor = verify_or_create_user(cpf)
      group.allocate_user(professor.id, 17)
    end
  end

  def get_group(curriculum_unit_code, course_code, code, period, year)
    semester = (period.blank? ? year : "#{year}.#{period}")
    Group.joins(offer: :semester).where(code: code, 
      offers: {curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
               course_id: Course.where(code: course_code).first},
      semesters: {name: semester}).first
  end

  def get_offer(curriculum_unit_code, course_code, period, year)
    semester = (period.blank? ? year : "#{year}.#{period}")
    Offer.joins(:semester).where(curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
               course_id: Course.where(code: course_code).first, semesters: {name: semester}).first
  end

  def get_destination(curriculum_unit_code, course_code, code, period, year)
    case
      when not(code.blank?)
        get_group(curriculum_unit_code, course_code, code, period, year)
      when not(year.blank?)
        get_offer(curriculum_unit_code, course_code, period, year)
      when not(curriculum_unit_code.blank?)
        CurriculumUnit.find_by_code(curriculum_unit_code)
      when not(course_code.blank?)
        Course.find_by_code(course_code)
      end
  end

  def get_offer_group(offer, group_code)
    offer.groups.where(code: group_code).first
  end

  # cancel all previous allocations and create new ones to groups
  def cancel_previous_and_create_allocations(groups, user, profile_id)
    # only curriculum units which type is 2
    user.groups(profile_id, nil, nil, 2).each do |group|
      group.change_allocation_status(user.id, 2, profile_id: profile_id) # cancel all users previous allocations as profile_id
    end

    groups.each do |group|
      group.allocate_user(user.id, profile_id)
    end
  end

  def get_profile_id(profile)
    ma_config = User::MODULO_ACADEMICO
    distant_professor_profile = (ma_config.nil? or not(ma_config['professor_profile'].present?) ? 17 : ma_config['professor_profile'])

    case profile.to_i
      when 1; 18 # tutor a distância UAB
      when 2; 4 # tutor presencial
      when 3; distant_professor_profile # professor titular UAB
      when 4; 1  # aluno
      when 17; 2 # professor titular
      when 18; 3 # tutor a distância
      else profile # corresponds to profile with id == allocation[:perfil]
    end
  end

  def copy_posts(from_posts, to_at, parent_id=nil)
    from_posts.each do |from_post|
      discussion = Discussion.find(from_post.academic_allocation.academic_tool_id)
      to_ac      = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Discussion", academic_tool_id: discussion.id).first
      new_post   = Post.where(from_post.attributes.except("id").merge("academic_allocation_id" => to_ac.id, "parent_id" => parent_id)).first_or_create

      from_post.files.each do |file|
        new_file = PostFile.where(file.attributes.except("id").merge("discussion_post_id" => new_post.id)).first_or_create
        copy_file(file.attachment.path, new_file.attachment.path)
      end

      from_children  = from_post.children
      copy_posts(from_children, to_at, new_post.try(:id)) unless from_children.empty?
    end
  end

  def copy_sent_assignments(from_sent_assignments, to_at)
    from_sent_assignments.each do |from_sent_assignment|

      assignment = Assignment.find(from_sent_assignment.academic_allocation.academic_tool_id)
      to_ac      = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Assignment", academic_tool_id: assignment.id).first
      
      attributes = from_sent_assignment.attributes.except("id", "grade").merge("academic_allocation_id" => to_ac.id) # user e group

      unless from_sent_assignment.group_assignment_id.nil?
        from_group = from_sent_assignment.group_assignment
        new_group  = GroupAssignment.where(group_name: from_group.group_name, academic_allocation_id: to_ac).first_or_create

        from_group.group_participants.each do |participant|
          GroupParticipant.where(group_assignment_id: new_group.id, user_id: participant.user_id).first_or_create
        end

        attributes = attributes.merge("group_assignment_id" => new_group.id)
      end

      new_sa = SentAssignment.where(attributes).first_or_create

      new_sa.update_attribute(:grade, from_sent_assignment.grade) # atualiza nota com a da turma que esta enviando os dados

      # replica comentarios e arquivos
      from_sent_assignment.assignment_comments.each do |from_comment|
        new_comment = AssignmentComment.where(from_comment.attributes.except("id", "updated_at").merge("sent_assignment_id" => new_sa.id)).first_or_create
        from_comment.comment_files.each do |file|
          new_file = CommentFile.where(file.attributes.except("id").merge("assignment_comment_id" => new_comment.id)).first_or_create
          copy_file(file.attachment.path, new_file.attachment.path)
        end
      end

      from_sent_assignment.assignment_files.each do |file|
        new_file = AssignmentFile.where(file.attributes.except("id").merge("sent_assignment_id" => new_sa.id)).first_or_create
        copy_file(file.attachment.path, new_file.attachment.path)
      end
    end
  end

  def replicate_content(from_group, to_group, merge = true)
    from_at, to_at = from_group.allocation_tag.id, to_group.allocation_tag.id

    ActiveRecord::Base.transaction do
      replicate_discussions(from_at, to_at)
      replicate_chats(from_at, to_at)
      replicate_assignments(from_at, to_at)
      replicate_messages(from_at, to_at)
      replicate_public_files(from_at, to_at)

      Merge.create main_group_id: from_group.id, secundary_group_id: to_group.id, type_merge: merge
      LogAction.create(log_type: LogAction::TYPE[:create], user_id: 0, ip: env['REMOTE_ADDR'], description: "merge: transfering content from #{from_group.code} to #{to_group.code}, merge type: #{merge}") rescue nil
    end
  end

  def copy_file(file_to_copy_path, file_copied_path)
    unless File.exists? file_copied_path or not(File.exists? file_to_copy_path)
      file = File.new file_copied_path, "w"
      FileUtils.cp file_to_copy_path, file # copia conteúdo para o arquivo criado
    end
  end

  def replicate_discussions(from_at, to_at)
    # recupera todos os foruns da turma a repassar dados
    from_discussions_academic_allocations = AcademicAllocation.where(allocation_tag_id: from_at, academic_tool_type: "Discussion")
    # recupera todos os foruns em comum da turma a receber dados
    to_discussions_academic_allocations   = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Discussion", academic_tool_id: from_discussions_academic_allocations.map(&:academic_tool_id))

    # se tiver algum forum na turma a repassar dados e nao na que vai receber
    missing_discussions = from_discussions_academic_allocations.map(&:academic_tool_id) - to_discussions_academic_allocations.map(&:academic_tool_id) 
    # duplica na turma que vai receber
    missing_discussions.each do |missing_discussion_id|
      AcademicAllocation.create(allocation_tag_id: to_at, academic_tool_type: "Discussion", academic_tool_id: missing_discussion_id)
    end

    from_posts = Post.where(parent_id: nil, academic_allocation_id: from_discussions_academic_allocations.map(&:id))
    copy_posts(from_posts, to_at) # clona o forum todo
  end

  # como vai ser a história dos participantes quando desaglutinar?
  def replicate_chats(from_at, to_at)
    # recupera todas as mensagens de chat da turma a repassar dados
    from_chats_academic_allocations = AcademicAllocation.where(allocation_tag_id: from_at, academic_tool_type: "ChatRoom")
    # recupera todas as mensagens de chat em comum da turma a receber dados
    to_chats_academic_allocations   = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "ChatRoom", academic_tool_id: from_chats_academic_allocations.map(&:academic_tool_id))

    # se tiver alguma mensagem de chat na turma a repassar dados e nao na que vai receber
    missing_chats = from_chats_academic_allocations.map(&:academic_tool_id) - to_chats_academic_allocations.map(&:academic_tool_id) 
    # duplica na turma que vai receber
    missing_chats.each do |missing_chat_id|
      AcademicAllocation.create(allocation_tag_id: to_at, academic_tool_type: "ChatRoom", academic_tool_id: missing_chat_id)
    end

    ChatRoom.where(id: from_chats_academic_allocations.map(&:academic_tool_id)).each do |chat|
      to_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "ChatRoom", academic_tool_id: chat.id).first

      chat.messages.each do |message|
        ChatMessage.where(message.attributes.except("id").merge("academic_allocation_id" => to_ac.id)).first_or_create  
      end

      chat.participants.each do |participant|
        ChatParticipant.where(participant.attributes.except("id").merge("academic_allocation_id" => to_ac.id)).first_or_create
      end
    end
  end

  def replicate_assignments(from_at, to_at)
    # recupera todos os trabalhos da turma a repassar dados
    from_assignments_academic_allocations = AcademicAllocation.where(allocation_tag_id: from_at, academic_tool_type: "Assignment")
    # recupera todos os trabalhos em comum da turma a receber dados
    to_assignments_academic_allocations = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: "Assignment", academic_tool_id: from_assignments_academic_allocations.map(&:academic_tool_id))

    # se tiver algum trabalho na turma a repassar dados e nao na que vai receber
    missing_assignments = from_assignments_academic_allocations.map(&:academic_tool_id) - to_assignments_academic_allocations.map(&:academic_tool_id) 
    # duplica na turma que vai receber
    missing_assignments.each do |missing_assignment_id|
      AcademicAllocation.create(allocation_tag_id: to_at, academic_tool_type: "Assignment", academic_tool_id: missing_assignment_id)
    end

    from_sent_assignments = SentAssignment.where(academic_allocation_id: from_assignments_academic_allocations.map(&:id))
    copy_sent_assignments(from_sent_assignments, to_at) # clona os envios dos trabalhos
  end

  def replicate_messages(from_at, to_at)
    from_messages_academic_allocations = Message.where(allocation_tag_id: from_at) # recupera todas as mensagens da turma a repassar dados

    from_messages_academic_allocations.each do |from_message|
      new_message = Message.where(from_message.attributes.except("id").merge("allocation_tag_id" => to_at)).first_or_create

      from_message.user_messages.each do |user|
        UserMessage.where(user.attributes.except("id").merge("message_id" => new_message.id)).first_or_create
      end
      from_message.files.each do |file|
        new_file = MessageFile.where(file.attributes.except("id").merge("message_id" => new_message.id)).first_or_create
        copy_file(file.attachment.path, new_file.attachment.path)
      end
      # replica label do usuario (ainda n existe, mas pra qd existir)
    end
  end

  def replicate_public_files(from_at, to_at)
    from_public_files_allocation_tags = PublicFile.where(allocation_tag_id: from_at) # recupera todos os arquivos da turma a repassar dados

    from_public_files_allocation_tags.each do |file|
      new_file = PublicFile.where(file.attributes.except("id").merge("allocation_tag_id" => to_at)).first_or_create
      copy_file(file.attachment.path, new_file.attachment.path)
    end
  end

end