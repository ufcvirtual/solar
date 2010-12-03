class User < ActiveRecord::Base
	acts_as_authentic do |c|
		c.require_password_confirmation = false
    	c.validates_length_of_password_field_options = {:minimum => 3}
		c.crypto_provider = CryptoProvider
	end

  # paperclip config to photo upload
  has_attached_file :photo,
    :styles => {:medium => "100x120>",
                :small => "25x30>"},
    :path => ":rails_root/public/images/:class/:id/:style_:basename.:extension",
    :url => "/images/:class/:id/:style_:basename.:extension",
    :default_url => "/images/no_image.png"

	#paperclip uses: file_name, content_type, file_size e updated_at

    #path and URL define that images will be in "public/images/"
    #  and will be created a folder called "users" with object id (eg users/1) 
    #default_url define default image (if image is dropped, for example)

    validates_attachment_presence :photo, :message => 'Image must be selected'
    validates_attachment_content_type :photo, :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg']#, :message => 'Image type invalid'

end
