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

  def verify_or_create_user(cpf)
    user = User.find_by_cpf(cpf.delete('.').delete('-'))

    return user if user

    user = User.new cpf: cpf
    user.connect_and_validates_user if user.can_synchronize?

    raise ActiveRecord::RecordNotFound unless user.valid? && !user.new_record?

    user
  end

  def get_destination(curriculum_unit_code, course_code, code, semester)
    case
      when !code.blank?
        get_group_by_codes(curriculum_unit_code, course_code, code, semester)
      when !semester.blank?
        get_offer(curriculum_unit_code, course_code, semester)
      when !curriculum_unit_code.blank?
        CurriculumUnit.find_by_code(curriculum_unit_code)
      when !course_code.blank?
        Course.find_by_code(course_code)
    end
  end 

end