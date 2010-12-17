class UserObserver < ActiveRecord::Observer

	def after_create(user)
		Log.create(:log_type => 2, :message => "Usuario " + user.name + " criado.")
	end

end
