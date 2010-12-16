class UserObserver < ActiveRecord::Observer

	def after_create(user)
		Log.create(:log_type => 'criacao de usuario', :message => "Usuario " + user.name + " criado.")
	end

end
