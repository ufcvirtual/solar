class UserObserver < ActiveRecord::Observer
  def after_create(user)
    LogAction.create(log_type: LogAction::TYPE[:new_user], user_id: user.id)
  end
end
