require 'rest_client'
class DigitalClass < ActiveRecord::Base
  GROUP_PERMISSION = true
    
  DC = YAML::load(File.open("config/digital_class.yml"))[Rails.env.to_s] rescue nil if File.exist?("config/digital_class.yml")

  def self.available?
    (!DC.nil? && DC["integrated"] && !RestClient.get(DC["path"]).nil?)
  rescue
    false # servidor indisponivel
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

    JSON.parse(res.body)
  rescue => error
    return error.response.code # indisponivel ou erro na chamada
  end

  def self.verify_and_create_member(user, allocation_tag)
    related_at = allocation_tag.related
    write_access = user.profiles_with_access_on('create', 'digital_classes', related_at).any?
    read_access  = user.profiles_with_access_on('access', 'digital_classes', related_at).any?
    if write_access || read_access
      permission = (write_access ? 'write' : 'read')
      directories = DigitalClassDirectory.get_directories_by_allocation_tag(allocation_tag).map(&:directory_id)
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
    return false unless DigitalClass.available?
    return false unless (!allocation.new_record? && ((allocation.status_changed? && allocation.status_was == Allocation_Activated) || allocation.profile_id_changed?)) || ignore_changes

    related_at   = allocation.allocation_tag.related
    write_access = allocation.user.profiles_with_access_on('create', 'digital_classes', related_at).any?
    read_access  = allocation.user.profiles_with_access_on('access', 'digital_classes', related_at).any?

    directories = DigitalClassDirectory.get_directories_by_allocation_tag(allocation.allocation_tag).map(&:directory_id)
    
    if !write_access && !read_access # if have no write or read access
      directories.each do |dir_id|
        DigitalClass.call('members_delete', { directory_id: dir_id, user_id: allocation.user.verify_or_create_at_digital_class }, ['directory_id'], :delete)
      end
    elsif (allocation.profile_id_changed? || ignore_changes) # if changes profile and still have write or read access
      directories.each do |dir_id|
        DigitalClass.call('members_update', { directory_id: dir_id, permission: (write_access ? 'write' : 'read'), user_id: allocation.user.verify_or_create_at_digital_class }, ['directory_id'], :put)
      end
    end
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.update_roles(allocation, professor_profiles=[], student_profiles=[], ignore_changes=false)
    return false unless DigitalClass.available?
    return false unless (!allocation.new_record? && allocation.profile_id_changed?) || ignore_changes
    
    professor_profiles = Profile.with_access_on('create', 'digital_classes') if professor_profiles.empty?
    student_profiles   = Profile.with_access_on('access', 'digital_classes') if student_profiles.empty?

    new_profile_professor = professor_profiles.include?(allocation.profile_id)
    return false if professor_profiles.include?(allocation.profile_id_was) && new_profile_professor

    DigitalClass.call('users_with_id', { user_id: allocation.user.verify_or_create_at_digital_class, role: (new_profile_professor ? 'professor' : allocation.user.get_digital_class_role) }, ['user_id'], :put)
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.update_user(user, ignore_changes=false)
    return false unless DigitalClass.available?
    return false if user.digital_class_user_id.nil?
    return false unless (!user.new_record? && (user.cpf_changed? || user.email_changed? || user.name_changed? || ignore_changes))

    DigitalClass.call('users_with_id', { user_id: user.digital_class_user_id, name: user.name, cpf: user.cpf, email: user.email }, ['user_id'], :put)
  rescue => error
    DigitalClass.rescue_ignore_changes(ignore_changes, error)
  end

  def self.update_multiple_users(users)
    users.each do |user|
      user.update_digital_class_user(true)
    end
  rescue => error
    raise error
  end

  def self.list_lessons_from_directory
    #DigitalClass.call('users_with_id', { user_id: dc_user_id, role: user.get_digital_class_role }, ['user_id'], :put)

  end

  private

    def self.access_token
      File.open(DC["token_path"], &:readline).strip
    end

    def self.rescue_ignore_changes(ignore_changes, error)
      if ignore_changes 
        raise error
      else 
        return false # nothing happens
      end
    end

end
