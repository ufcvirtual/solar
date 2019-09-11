module V1::AllocationsH

  ## remover
  def allocate_professors(group, cpfs)
    group.allocations.where(profile_id: 17).update_all(status: 2) # cancel all previous allocations

    cpfs = cpfs.reject { |c| c.empty? }
    cpfs.each do |cpf|
      professor = verify_or_create_user(cpf)

      if professor.try(:id).blank?
        Rails.logger.info "[API] [WARNING] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: Não foi possível cadastrar o professor de cpf #{cpf} - SI3 não enviou os dados"
      end

      group.allocate_user(professor.id, 17)
    end
  end

  # cancel all previous allocations and create new ones to groups
  def create_allocations(groups, user, profile_id)
    ActiveRecord::Base.transaction do
      groups.each do |group|
        group.first.allocate_user(user.id, profile_id, nil, group.last.try(:id))
        unless group.last.blank?
          # set or create merged allocation
          group.last.allocate_user(user.id, profile_id, nil, nil, 5)
        else
          # cancel possible previous merges allocations
          Allocation.where(origin_group_id: group.first.id, user_id: user.id, profile_id: profile_id).each do |al|
            al.update_attributes origin_group_id: nil
            al.group.change_allocation_status(user.id, Allocation_Cancelled, nil, {profile_id: profile_id})
          end
        end
      end
    end
  end

  def cancel_allocations(groups, user, profile_id)
    ActiveRecord::Base.transaction do
      groups.each do |group|
        # cancel all users previous allocations as profile_id
        group.first.change_allocation_status(user.id, 2, nil, {profile_id: profile_id, origin_group_id: group.last.try(:id), create_if_dont_exists: true})

        Allocation.where(origin_group_id: group.first.id, user_id: user.id, profile_id: profile_id).each do |al|
          al.group.change_allocation_status(user.id, Allocation_Cancelled, nil, {profile_id: profile_id})
        end
      end
    end
  end

  def cancel_all_allocations(profile_id, semester_id)
    ucs = CurriculumUnitType.find(2).curriculum_units.map(&:id)
    params = { curriculum_unit_id: ucs }
    params.merge!(semester_id: semester_id) #unless config not defined
    taggables = RelatedTaggable.joins(:offer).where(offers: params).select('COALESCE(group_at_id, offer_at_id) AS at').map(&:at).map(&:to_i)
    Allocation.where(allocation_tag_id: taggables, profile_id: profile_id).update_all updated_at: Time.now, status: Allocation_Cancelled, updated_by_user_id: nil
  end

  def get_profile_id(profile)
    ma_config = User::MODULO_ACADEMICO
    distant_professor_profile = (ma_config.nil? || !(ma_config['professor_profile'].present?) ? 17 : ma_config['professor_profile'])

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
  ## remover

  def allocate(params, cancel = false, raise_error=false, notify=false, verify_access=false)
    objects = ( params[:id].nil? ?  get_destination(params[:curriculum_unit_code], params[:course_code], params[:group_name], params[:semester], params[:group_code]) : params[:type].capitalize.constantize.where(id: params[:id]) )
    users  = get_users(params)


    raise ActiveRecord::RecordNotFound if users.empty?
    if verify_access
      raise CanCan::AccessDenied if users.map(&:oauth_application_id).compact.blank? || users.map(&:oauth_application_id).uniq != [@current_client.id]
      authorize_client!([objects].flatten.map(&:allocation_tag).map(&:id).flatten)
    end

    [objects].flatten.map{|object| object.cancel_allocations(nil, params[:profile_id])} if params[:remove_previous_allocations]

    users.each do |user|
      if(user.try(:id).blank? && params[:profile_id] != 4)
        Rails.logger.info "[API] [WARNING] [#{Time.now}] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [404] message: Não foi possível cadastrar o usuário de cpf #{user.try(:cpf)} - SI3 não enviou os dados"
      end
      user.cancel_allocations(params[:profile_id]) if params[:remove_user_previous_allocations]
      [objects].flatten.map do |object|
        if cancel
          object.cancel_allocations(user.id, params[:profile_id], nil, {}, raise_error)
        else
          object.allocate_user(user.id, params[:profile_id], nil, nil, Allocation_Activated, notify)
        end
      end
    end
  end

  def get_users(params, users=[])
    users << case
    when params[:user_id].present?
      User.find(params[:user_id])
    when params[:users_ids].present?
      User.where(id: params[:users_ids])
    when params[:cpf].present?
      User.where(cpf: params[:cpf].delete('.').delete('-')).first
    else
      User.where(cpf: params[:cpfs])
    end

    users << import_users(params) if (params[:cpf].present? || params[:cpfs].present?) && params[:ma]
    users.compact.flatten
  end

  def import_users(params)
    users = []
    [params[:cpf] || params[:cpfs]].flatten.each do |cpf|
      users << verify_or_create_user(cpf, params[:ma])
    end
    users
  end

end