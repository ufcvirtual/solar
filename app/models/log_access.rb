class LogAccess < ActiveRecord::Base

  belongs_to :user
  belongs_to :allocation_tag

  default_scope order: 'created_at DESC'

  TYPE = {
    login: 1,
    group_access: 2
  }

  def type_name
    type = case log_type
      when 1
        :login
      when 2
        :group_access
    end
    I18n.t(type, scope: 'administrations.logs.types')
  end

  def self.group(params)
    params.merge!(log_type: TYPE[:group_access])
    create(params)
  end

  def self.login(params)
    params.merge!(log_type: TYPE[:login])
    create(params)
  end

end
