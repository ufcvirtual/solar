class LogAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :allocation_tag

  TYPE = {
    login: 1,
    curriculum_unit_access: 2
  }

  ## quem era 3 vira 2
  ## quem era 2 vira um outro log
    ## aplicar na migration

  def self.course(params)
    params.merge!(log_type: TYPE[:curriculum_unit_access])
    create(params)
  end

  def self.login(params)
    params.merge!(log_type: TYPE[:login])
    create(params)
  end

end
