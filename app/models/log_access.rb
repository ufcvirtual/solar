class LogAccess < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :allocation_tag

  default_scope order: 'created_at DESC'

  TYPE = {
    login: 1,
    offer_access: 2
  }

  def type_name
    type = case log_type
      when 1
        :login
      when 2
        :offer_access
    end
    I18n.t(type, scope: 'administrations.logs.types')
  end


  ## class methods


  def self.offer(params)
    params.merge!(log_type: TYPE[:offer_access])
    create(params)
  end

  def self.login(params)
    params.merge!(log_type: TYPE[:login])
    create(params)
  end

end
