module V1::General

  def verify_ip_access!
    Rails.logger.info "[API] [WARNING] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] message: Checking for IP permission"
    raise CanCan::AccessDenied unless YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(request.headers['HTTP_CLIENT_IP']) || YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(request.env['HTTP_X_FORWARDED_FOR'].to_s) || YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(env['REMOTE_ADDR'])

  end

  def authorize_client!(ats_ids)
    raise CanCan::AccessDenied unless AllocationTagOwner.where(allocation_tag_id: ats_ids, oauth_application_id: @current_client.id).count == [ats_ids].flatten.compact.size
  end

  def verify_ip_access_and_guard!
    begin
      verify_ip_access!
    rescue
      begin
        raise CanCan::AccessDenied unless YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(request.env['HTTP_X_FORWARDED_FOR'].to_s) || YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(env['REMOTE_ADDR'])

      rescue
        Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [401] message: Error while checking for IP permission"
        Rails.logger.info "[API] [WARNING] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] message: Checking for access_token permission"
        guard_user!
      end
    end
  end

  def log_error(error, code)
    Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [#{code}] message: #{error}"
  end

  def log_info(msg)
    Rails.logger.info "[API] [INFO] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"].except("password")}] message: #{msg}"
  end


  def verify_or_create_user(cpf, ignore_synchronize=false, only_if_exists=false, import=false, ignore_raise_error=false)
    user = User.find_by_cpf(cpf.delete('.').delete('-'))
    user = User.new(cpf: cpf) unless user || only_if_exists

    return true if only_if_exists && user.blank?

    return user if user.selfregistration && !import

    if user.can_synchronize?  && (!ignore_synchronize || user.new_record?)
      import = user.synchronize
      return user if(import.blank? && !user.new_record?)
      raise user.errors.full_messages.join(', ') unless import || user.errors.empty?
      raise "error while synchronize new user #{cpf}" if !import && user.try(:id).blank? && !ignore_raise_error
    else
      Rails.logger.info Rails.logger.info "[API] [INFO] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] user #{cpf} was not synchronized - blacklist or ignore param activated"
    end

    return user
  end

  def get_destination(curriculum_unit_code, course_code, group_name, semester, group_code=nil)
    case
      when !group_name.blank? && !group_code.blank?
        get_group_by_code_and_name(curriculum_unit_code, course_code, group_name, semester, group_code)
      when !group_name.blank?
        get_group_by_names(curriculum_unit_code, course_code, group_name, semester)
      when !group_code.blank?
        get_groups_by_code(curriculum_unit_code, course_code, group_code, semester)
      when !semester.blank?
        get_offer(curriculum_unit_code, course_code, semester)
      when !curriculum_unit_code.blank?
        CurriculumUnit.find_by_code(curriculum_unit_code)
      when !course_code.blank?
        Course.find_by_code(course_code)
      else
        raise ActiveRecord::RecordNotFound
    end
  end

  def get_group_destination_randomly(curriculum_unit_code, course_code, start_date, end_date, cpf=nil, profile=nil, all=false)
    group_id = nil
    course = Course.find_by_code!(course_code)
    uc = CurriculumUnit.find_by_code!(curriculum_unit_code)
    offers = Offer.joins("JOIN semesters ON semesters.id = offers.semester_id")
                  .joins("LEFT JOIN schedules AS oschedules ON oschedules.id = offers.offer_schedule_id")
                  .joins("LEFT JOIN schedules AS sschedules ON sschedules.id = semesters.offer_schedule_id")
                  .where(curriculum_unit_id: uc.id, course_id: course.id)
                  .where("(offers.offer_schedule_id IS NULL AND sschedules.start_date::date = '#{start_date}'::date AND sschedules.end_date::date = '#{end_date}'::date) OR (offers.offer_schedule_id IS NOT NULL AND oschedules.start_date::date = '#{start_date}'::date AND oschedules.end_date::date = '#{end_date}'::date)")

    raise ActiveRecord::RecordNotFound if offers.empty?
    profile_id = Profile.student_profile

    groups = Group.joins(:allocation_tag)
                  .joins("LEFT JOIN allocations ON (allocations.allocation_tag_id = allocation_tags.id AND profile_id = #{profile_id} AND allocations.status = #{Allocation_Activated})")
                  .where(offer_id: offers.map(&:id), status: true)
                  .select("COUNT(allocations.user_id) AS students, groups.name, groups.id")
                  .group("groups.name, groups.id")
                  .order("COUNT(allocations.user_id)")

    raise ActiveRecord::RecordNotFound if groups.empty?

    unless cpf.blank? || profile.blank?
      user = User.where(cpf: cpf).first
      unless user.blank?
        allocations = Allocation.where(user_id: user.id, profile_id: profile, allocation_tag_id: groups.map(&:allocation_tag).map(&:id))
        unless allocations.blank?
          if all
            groups_ids = allocations.where(status: 1).map(&:allocation_tag).map(&:group_id)
          else
            group_id = if allocations.where(status: 1).any?
              allocations.where(status: 1).first.allocation_tag.group_id
            else
              allocations.first.allocation_tag.group_id
            end
          end
        end
      end
    end

    if all
      (groups_ids || groups.collect{|a| a[:id]})
    else
      (group_id || groups.first[:id])
    end
  end


  def get_group_code(code, name, year=nil)
    # groups created at MA before integration with SI3 have a name with
    # a pattern, but after integration, all groups created at SI3 have
    # another pattern.
    # code must have to be equal from name if created by MA

    return name if code.blank? && !year.nil? && year <= 2018 # MA group without a location
    return (name.include?(code.delete('_')) ? name : code) unless code.blank?

    return nil
  end

end