class UserObserver < ActiveRecord::Observer
  def after_create(user)
    Log.create(log_type: Log::TYPE[:new_user], user_id: user.id)
  end
end
