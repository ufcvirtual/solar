class LogAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :allocation_tag

  TYPE = {
    login: 1,
    curriculum_unit_access: 2
  }

  def self.course(params)
    params.merge!(log_type: TYPE[:curriculum_unit_access])
    create(params)
  end

  def self.login(params)
    params.merge!(log_type: TYPE[:login])
    create(params)
  end

  def type_name
    case log_type
      when 1
        I18n.t(:login, scope: [:administrations, :logs, :types])
      when 2
        I18n.t(:curriculum_unit_access, scope: [:administrations, :logs, :types])
    end
  end

end
