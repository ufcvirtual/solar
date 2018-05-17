module V1::General

  def verify_ip_access!
    raise CanCan::AccessDenied unless YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(request.headers['HTTP_CLIENT_IP'])
  end

  def verify_ip_access_and_guard!
    begin
      verify_ip_access!
    rescue
      begin
        raise CanCan::AccessDenied unless YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s]['verified_addresses'].include?(env['REMOTE_ADDR'])
      rescue
        Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [401] message: Error while checking for IP permission"
        Rails.logger.info "[API] [WARNING] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] message: Checking for access_token permission"
        guard!
      end
    end
  end

  def log_error(error, code)
    Rails.logger.info "[API] [ERROR] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] [#{code}] message: #{error}"
  end

  def log_info(msg)
    Rails.logger.info "[API] [INFO] [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}] message: #{msg}"
  end


  def verify_or_create_user(cpf, ignore_synchronize=false, only_if_exists=false)
    user = User.find_by_cpf(cpf.delete('.').delete('-'))
    user = User.new(cpf: cpf) unless user || only_if_exists

    return true if only_if_exists && user.blank?

    return user if user.selfregistration

    if user.can_synchronize?  && (!ignore_synchronize || user.new_record?)
      import = user.synchronize
      return user if(import.blank? && !user.new_record?)
      raise user.errors.full_messages.join(', ') unless import || user.errors.empty?
      raise "error while synchronize new user #{cpf}" if !import && user.try(:id).blank?
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