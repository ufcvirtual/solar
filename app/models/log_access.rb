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

end
