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
    group.allocations.where(profile_id: 2).update_all(status: 2) # cancel all previous allocations

    cpfs.each do |cpf|
      professor = verify_or_create_user(cpf)
      group.allocate_user(professor.id, 2)
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
    user.groups(profile_id).each do |group|
      group.change_allocation_status(user.id, 2, profile_id: profile_id) # cancel all users previous allocations as profile_id
    end

    groups.each do |group|
      group.allocate_user(user.id, profile_id)
    end
  end

  def get_profile_id(profile)
    case profile.to_i
      when 1; 3 # tutor a distância
      when 2; 4 # tutor presencial
      when 3; 2 # professor titular
      when 4; 1 # aluno
      else profile # corresponds to profile with id == allocation[:perfil]
    end
  end

end