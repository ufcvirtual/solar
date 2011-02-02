class User < ActiveRecord::Base

  #Garantindo que o cpf nao será salvo com os separadores.
  def cpf=(value)
    self[:cpf] = value.gsub(/\D/, '')
  end

  #Protege o campo de senha da atualização em massa (update_attributes).
  attr_accessible :login,:email,:name,:birthdate,:cpf,:address,:address_number
  attr_accessible :address_neighborhood,:zipcode,:country,:state,:city
  attr_accessible :institution,:enrollment_code, :special_needs, :address
  attr_accessible :address_number, :address_complement, :address_neighborhood
  attr_accessible :zipcode, :country, :state, :city, :telephone, :cell_phone
  attr_accessible :institution,:bio, :interests, :music,:movies,:books,:phrase
  attr_accessible :site, :nick

  #Validação de tamanho dos campos
  # validacao do comprimento da senha no :create
  validates_length_of :password, :within => 6..60, :too_long => "deve ter menos de 60 caracteres", :too_short => "deve ter 6 ou mais caracteres", :on => :create
  # validacao do comprimento da senha no :update
  #?????/



  #campos obrigatórios#
  validates_presence_of :login,:email,:name,:birthdate,:cpf,:address, :message => "deve ser preenchido!"
  validates_presence_of :address_number,:address_neighborhood,:zipcode,:country, :message => "deve ser preenchido!"
  validates_presence_of :state,:city,:institution, :message => "deve ser preenchido!"
  validates_presence_of :password, :on => :create  #Senha é apenas no create

  #validaçao do CPF
  usar_como_cpf :cpf

	#campos únicos#
  validates_uniqueness_of :cpf,:login,:email,:message=>"ja cadastrado"

  #Confirmação de senha e email.
  validates_confirmation_of :password, :message=> "deve ser igual a confirmacao de senha"

	#Detalhes da Senha #
  acts_as_authentic do |c|
		#c.require_password_confirmation = false
		#c.validates_length_of_password_field_options = {:minimum => 3}
		c.crypto_provider = CryptoProvider
	end

  # Configuração do paperclip para upload de fotos
  has_attached_file :photo,
    :styles => {:medium => "100x120>",
    :small => "25x30>"},
    :path => ":rails_root/public/images/:class/:id/:style_:basename.:extension",
    :url => "/images/:class/:id/:style_:basename.:extension",
    :default_url => "/images/no_image.png"

  # paperclip uses: file_name, content_type, file_size e updated_at
  
  #path and URL define that images will be in "public/images/"
  #  and will be created a folder called "users" with object id (eg users/1)
  #default_url define default image (if image is dropped or not exists)

  #validates_attachment_presence :photo, :message => 'Image must be selected'
  validates_attachment_content_type :photo, :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg']#, :message => 'Invalid image type!'

end
