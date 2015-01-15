module V1::UsersH

  def user_params(params)
    ActionController::Parameters.new(params).except("route_info").permit(:username, :email, :email_confirmation, :alternate_email, :password, :password_confirmation,
        :remember_me, :name, :nick, :birthdate, :address, :address_number, :address_complement, :address_neighborhood,
        :zipcode, :country, :state, :city, :telephone, :cell_phone, :institution, :gender, :cpf, :bio, :interests, :music,
        :movies, :books, :phrase, :site, :photo, :special_needs, :active)
  end

end
