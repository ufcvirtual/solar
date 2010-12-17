class UserObserver < ActiveRecord::Observer

	def after_create(user)
		Log.create(:log_type => Log::TYPE[:new_user], :userId => user.id)
	end

end
