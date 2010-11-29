class User < ActiveRecord::Base
	acts_as_authentic do |c|
		c.require_password_confirmation = false
    	c.validates_length_of_password_field_options = {:minimum => 3}
		c.crypto_provider = CryptoProvider
	end
end
