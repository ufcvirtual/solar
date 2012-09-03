class TagObserver < ActiveRecord::Observer
  observe :course, :curriculum_unit, :offer, :group
 
  def before_destroy(model)
    Log.create(log_type: Log::TYPE[:destroy], user_id: model.user_id, message: model.inspect)
  end
end