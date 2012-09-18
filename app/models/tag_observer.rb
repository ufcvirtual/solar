class TagObserver < ActiveRecord::Observer
  observe :course, :curriculum_unit, :offer, :group
 
  def after_destroy(model)
    Log.create(log_type: Log::TYPE[:destroy], user_id: model.user_id, description: model.inspect)
  end
end