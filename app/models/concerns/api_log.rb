module APILog
  extend ActiveSupport::Concern

  included do
    after_create if: 'from_api?' do
      create_log_api('create', self)
    end

    after_update if: 'from_api?' do
      create_log_api('update', self)
    end

    before_destroy if: 'from_api?' do
      create_log_api('destroy', self)
    end

    attr_accessor :api
  end

  def current_user
    Thread.current[:user]
  end

  def self.current_user=(user)
    Thread.current[:user] = user
  end

  def remote_ip
    Thread.current[:ip]
  end

  def self.remote_ip=(ip)
    Thread.current[:ip] = ip
  end

  def from_api?
    api
  end

  def create_log_api(log_type, model)
    description = "[API] #{model.class}: #{model.id}, #{ActiveSupport::JSON.encode(model.attributes.except('attachment_updated_at', 'updated_at', 'created_at', 'id'))}" unless model.nil?

    if (model.respond_to?(:allocation_tag) && !(model.allocation_tag.nil?))
      LogAction.create(log_type: LogAction::TYPE[log_type.to_sym], user_id: (current_user.nil? ? nil : current_user.id), allocation_tag_id: model.allocation_tag.id, ip: remote_ip, description: description) unless description.nil?
    else
      ac_id = model.academic_allocation.id if model.respond_to?(:academic_allocation)
      all_tag_id = model.allocation_tag_id if model.respond_to?(:allocation_tag_id)
      acu_id = model.academic_allocation_user_id if model.respond_to?(:academic_allocation_user_id)

      LogAction.create(log_type: LogAction::TYPE[log_type.to_sym], user_id: (current_user.nil? ? nil : current_user.id), ip: remote_ip, description: description, academic_allocation_id: ac_id, allocation_tag_id: all_tag_id, academic_allocation_user_id: acu_id) unless description.nil?
    end
  end
end
