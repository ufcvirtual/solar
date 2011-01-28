class User < ActiveRecord::Base

  def cpf=(value)
    self[:cpf] = value.gsub(/\D/, '')
  end
  #campos obrigatórios#
  validates_presence_of :login,:email,:password,:name,:birthdate,:cpf,:address,:address_number,:address_neighborhood,:zipcode,:country,:state,:city,:institution, :message => "deve ser preenchido!"

  #validaçao do CPF
  usar_como_cpf :cpf

	#verificação de unicidade
  validates_uniqueness_of :cpf,:login,:email,:message=>"ja cadastrado"

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

    # paperclip uses: file_name, content_type, file_size e updated_at
    validates_confirmation_of :password, :message=> "deve ser igual a confirmacao de senha"
    #path and URL define that images will be in "public/images/"
    #  and will be created a folder called "users" with object id (eg users/1) 
    #default_url define default image (if image is dropped or not exists)

    #validates_attachment_presence :photo, :message => 'Image must be selected'
    validates_attachment_content_type :photo, :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg']#, :message => 'Invalid image type!'

end
