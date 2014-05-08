class LogAction < ActiveRecord::Base
  belongs_to :user

  TYPE = {
    create: 1,
    update: 2,
    destroy: 3,
    new_user: 4,
    block_user: 5,
    request_password: 6
  }

  def self.new_user(params)
    params.merge!(log_type: TYPE[:new_user])
    create(params)
  end

  def self.block_user(params)
    params.merge!(log_type: TYPE[:block_user])
    create(params)
  end

  def self.request_password(params)
    params.merge!(log_type: TYPE[:request_password])
    create(params)
  end

  def self.creating(params)
    params.merge!(log_type: TYPE[:create])
    create(params)
  end

  def self.updating(params)
    params.merge!(log_type: TYPE[:update])
    create(params)
  end

  def self.destroying(params)
    params.merge!(log_type: TYPE[:destroy])
    create(params)
  end

end
