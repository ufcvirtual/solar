require 'rest_client'
class DigitalClass < ActiveRecord::Base
  GROUP_PERMISSION = true

  DC = YAML::load(File.open("config/digital_class.yml"))[Rails.env.to_s] rescue nil if File.exist?("config/digital_class.yml")

  def self.available?
    (!DC.nil? && DC["integrated"] && !RestClient.get(DC["path"]).nil?)
  rescue => error
    DigitalClass.log_info('ERROR', [], "[Server Unavailable] Message: #{error}")
    false # servidor indisponivel
  end

  def self.dc_logger
    Logger.new(DC['log'])
  end

  def self.call(path, params={}, replace=[], method=:get)
    url = File.join(DC["url"], DC["paths"][path])
    replace.each do |string|
      url.gsub! ":#{string}", params[string.to_sym].to_s
    end

    res = if method == :get || method == :delete
      RestClient.send(method, url, { params: { access_token: self.access_token, accept: :json, content_type: 'x-www-form-urlencoded', 'Authorization' => "Bearer #{self.access_token}" }.merge!(params) })
    else
      RestClient.send(method, url, { access_token: self.access_token }.merge!(params), { accept: :json, content_type: 'x-www-form-urlencoded' })
    end

    response = JSON.parse(res.body)

    DigitalClass.log_info('SUCCESS', [method, path], "Params: #{params} Replace Params: #{replace.join(', ')} Return: #{response}")

    response
  rescue => error
    DigitalClass.log_info('ERROR', [method, path], "Params: #{params} Replace Params: #{replace.join(', ')} Error Code: #{error.try(:response).try(:code)} Error Message: #{error.try(:response).try(:body)}")
    return error.response.code # indisponivel ou erro na chamada
  end

  def self.verify_and_create_member(user, allocation_tag)
    related_at = allocation_tag.related
    write_access = user.profiles_with_access_on('create', 'digital_classes', related_at).any?
    read_access  = user.profiles_with_access_on('access', 'digital_classes', related_at).any?
    if write_access || read_access
      permission = (write_access ? 'write' : 'read')
      directories = DigitalClass.get_directories_by_allocation_tag(allocation_tag)
      if directories.any?
        dc_user_id = user.verify_or_create_at_digital_class 
        DigitalClass.call('users_with_id', { user_id: dc_user_id, role: user.get_digital_class_role }, ['user_id'], :put)
        directories.each do |dir_id|
          member = DigitalClass.call('members_new', { directory_id: dir_id, permission: permission, user_id: dc_user_id }, ['directory_id'], :post)
          DigitalClass.call('members_update', { directory_id: dir_id, permission: permission, user_id: dc_user_id }, ['directory_id'], :put)  if member['permission'] != permission
        end
      end
    end
  end

  def self.update_members(allocation, ignore_changes=false)
    return false unless ignore_changes || DigitalClass.available?
    return false unless (!allocation.new_record? && ((allocation.status_changed? && allocation.status_was == Allocation_Activated) || allocation.profile_id_changed?)) || ignore_changes
    return false if (user_dc_id = allocation.user.verify_or_create_at_digital_class).nil?

    related_at   = allocation.allocation_tag.related
    write_access = allocation.user.profiles_with_access_on('create', 'digital_classes', related_at).any?
    read_access  = allocation.user.profiles_with_access_on('access', 'digital_classes', related_at).any?

    directories = DigitalClass.get_directories_by_allocation_tag(allocation.allocation_tag)

    if !write_access && !read_access # if have no write or read access
      directories.each do |dir_id|
        DigitalClass.call('members_delete', { directory_id: dir_id, user_id: user_dc_id }, ['directory_id'], :delete)
        DigitalClass.call('users_with_id', { user_id: user_dc_id, role: (allocation.user.get_digital_class_role rescue 'student') }, ['user_id'], :put)
      end
    elsif (allocation.profile_id_changed? || ignore_changes) # if changes profile and still have write or read access
      directories.each do |dir_id|
        DigitalClass.call('members_update', { directory_id: dir_id, permission: (write_access ? 'write' : 'read'), user_id: user_dc_id }, ['directory_id'], :put)
      end
    end
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.update_roles(allocation, professor_profiles=[], student_profiles=[], ignore_changes=false)
    return false unless ignore_changes || DigitalClass.available?
    return false unless (!allocation.new_record? && allocation.profile_id_changed?) || ignore_changes
    return false if (user_dc_id = allocation.user.verify_or_create_at_digital_class).nil?

    professor_profiles = Profile.with_access_on('create', 'digital_classes') if professor_profiles.empty?
    student_profiles   = Profile.with_access_on('access', 'digital_classes') if student_profiles.empty?

    new_profile_professor = professor_profiles.include?(allocation.profile_id)
    return false if professor_profiles.include?(allocation.profile_id_was) && new_profile_professor

    DigitalClass.call('users_with_id', { user_id: user_dc_id, role: (new_profile_professor ? 'professor' : allocation.user.get_digital_class_role) }, ['user_id'], :put)
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.update_user(user, ignore_changes=false)
    return false unless ignore_changes || DigitalClass.available?
    return false if user.digital_class_user_id.nil?
    return false unless (!user.new_record? && (user.cpf_changed? || user.email_changed? || user.name_changed? || ignore_changes))

    DigitalClass.call('users_with_id', { user_id: user.digital_class_user_id, name: user.name, cpf: user.cpf, email: user.email }, ['user_id'], :put)
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.update_multiple(initial_date, allocation_tags=[])
    return false unless DigitalClass.available?
    query  = ['updated_at::date >= :initial_date']
    query1 = [query.join(' AND '), { initial_date: initial_date }]

    DigitalClass.update_multiple_users(User.where(query1))

    unless allocation_tags[:allocation_tags].compact.blank?
      ats = RelatedTaggable.related_from_array_ats(allocation_tags[:allocation_tags].compact)
      query << 'allocation_tags.id IN (:allocation_tags)' 
      query2 = [query.join(' AND '), { initial_date: initial_date, allocation_tags: ats }]
      query3 = ['group_at_id IN (:allocation_tags) OR offer_at_id IN (:allocation_tags) OR course_at_id IN (:allocation_tags) OR curriculum_unit_at_id IN (:allocation_tags) OR curriculum_unit_type_at_id IN (:allocation_tags)', { allocation_tags: ats }]
    else
      query << 'allocation_tags.id IS NOT NULL'
      query2 = query1
      query3 = ''
    end

    DigitalClass.update_multiple_taggables(Taggable.descendants.map{|model| model.joins(:allocation_tag).where(query2)})
    DigitalClass.update_multiple_taggables(Semester.joins(:related_taggables).where(query1).where(query3))

    query2[0] = query2[0].gsub('updated_at', 'allocations.updated_at')
    DigitalClass.update_multiple_allocations(Allocation.joins(:allocation_tag, :user).where(query2).where('users.digital_class_user_id IS NOT NULL'))
  rescue => error
    raise error
  end

  def self.update_multiple_allocations(allocations)
    professor_profiles = Profile.with_access_on('create', 'digital_classes')
    student_profiles   = Profile.with_access_on('access', 'digital_classes')
    allocations.each do |allocation|
      allocation.update_digital_class_members(true)
      allocation.update_digital_class_user_role(professor_profiles, student_profiles, true)
    end
  end

  def self.update_multiple_users(users)
    users.each do |user|
      user.update_digital_class_user(true)
    end
  end

  def self.update_multiple_taggables(taggables)
    taggables.flatten.uniq.each do |taggable|
      DigitalClass.update_taggable(taggable, true)
    end
  end

  def self.list_lessons_from_directory
    #DigitalClass.call('users_with_id', { user_id: dc_user_id, role: user.get_digital_class_role }, ['user_id'], :put)
  end

  def self.get_lesson(lesson_id)
    DigitalClass.call('lessons_with_id', { lesson_id: lesson_id }, ['lesson_id'])
  end

  def self.update_lesson(digital_class_params, id)
    lesson = get_lesson(id)
    lesson_id = lesson['id']
    if digital_class_params && lesson_id
      DigitalClass.call('lessons_with_id', { lesson_id: lesson_id, name: digital_class_params['name'], description: digital_class_params['description'] }, ['lesson_id'], :put)
    end
  end

  def self.delete_lesson(lesson_id)
    DigitalClass.call('lessons_with_id', { lesson_id: lesson_id }, ['lesson_id'], :delete)
  end

  def self.create_lesson(dc_directory_id, dc_user_id, digital_class_params)
    if dc_directory_id && dc_user_id && digital_class_params
      lesson = DigitalClass.call('lessons', { name: digital_class_params[:name], directories: dc_directory_id, user_id: dc_user_id, description: digital_class_params['description'] }, [], :post)
      lesson['redirect_url']
    end  
  end

  def self.add_lesson_to_directories(directories_ids, lesson_id)
    if directories_ids && lesson_id
      directories_ids.each do |directory_id|
        DigitalClass.call('dir_lessons_new', { directory_id: directory_id, lesson_id: lesson_id }, ['directory_id'], :post)
      end
    end
  end

  def self.remove_lesson_from_directories(directories_ids, lesson_id)
    if directories_ids && lesson_id
      directories_ids.each do |directory_id|
        DigitalClass.call('dir_lessons_delete', { directory_id: directory_id, lesson_id: lesson_id }, ['directory_id'], :delete)
      end
    end
  end

  def self.update_taggable(object, ignore_changes=false)
    return false unless ignore_changes || DigitalClass.available?

    groups = (object.class == Group ? [object] : object.groups)
    groups.reject{ |g| g.digital_class_directory_id.blank? }.compact.each do |group|
      DigitalClass.call('directories_with_id', { directory_id: group.digital_class_directory_id }.merge!(group.params_to_directory), ['directory_id'], :put)
    end
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.get_directories_by_allocation_tag(allocation_tag)
    column = "#{allocation_tag.refer_to}_id"
    Group.joins(:related_taggables).where(related_taggables: { column => allocation_tag.send(column) }).uniq.map(&:digital_class_directory_id).compact
  end

  def self.get_directories_by_object(object)
    column = "#{object.class.to_s.tableize.singularize}_id"
    Group.joins(:related_taggables).where(related_taggables: { column => object.id }).uniq.map(&:digital_class_directory_id).compact
  end

  def self.get_lessons_by_directory(directory_id)
    DigitalClass.call('lessons_by_directory', { directory_id: directory_id }, ['directory_id'], :get)
  end

  private
    def self.access_token
      File.open(DC["token_path"], &:readline).strip
    end

    def self.rescue_ignore_changes(ignore_changes, error)
      if ignore_changes
        DigitalClass.log_info('ERROR', [], "Message: #{error}")
        raise error
      else 
        return false # nothing happens
      end
    end

    def self.log_info(type, info=[], text='')
      log = []
      log << "\n#{Time.now} [#{type}]"
      info.each do |i|
        log << "[#{i}]"
      end
      log << text
      DigitalClass.dc_logger.info log.join(' ')
    end
  
end
