class LogAction < ActiveRecord::Base

  belongs_to :user
  belongs_to :allocation_tag
  belongs_to :academic_allocation
  belongs_to :academic_allocation_user

  TYPE = {
    create: 1,
    update: 2,
    destroy: 3,
    new_user: 4,
    block_user: 5,
    request_password: 6,
    access_webconference: 7,
    access_digital_class_lesson: 8
  }

  before_save :set_acu, if: '!academic_allocation_user_id.nil? && log_type != 7'

  def set_acu
    self.academic_allocation_user_id = nil
  end

  def type_name
    type = case log_type
      when 1
        :create
      when 2
        :update
      when 3
        :destroy
      when 4
        :new_user
      when 5
        :block_user
      when 6
        :request_password
      when 7
        :access_webconference
      when 8
        :access_digital_class_lesson
    end

    I18n.t(type, scope: 'administrations.logs.types')
  end

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

  def self.access_webconference(params)
    params.merge!(log_type: TYPE[:access_webconference])
    create(params)
  end

  def self.access_digital_class_lesson(params)
    params.merge!(log_type: TYPE[:access_digital_class_lesson])
    create(params)
  end

end
