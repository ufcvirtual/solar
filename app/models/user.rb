class User < ActiveRecord::Base

  has_many :allocation

  #Garantindo que o cpf nao será salvo com os separadores.
  def cpf=(value)
    self[:cpf] = value.gsub(/\D/, '')
  end

  #Protege o campo de senha da atualização em massa (update_attributes).
  attr_protected :password

  # validacao do comprimento da senha no :create
  validates :password,:presence =>true, :length => {:within => 6..60},:confirmation => true, :on => :create
  # validacao do comprimento da senha no :update

  #Validações campo a campo
  #Campos pendentes devido ao authlogic
  #Fazer o logn depois
  validates :login, :presence => true ,:length => { :within => 3.. 20}, :uniqueness => true
  #Fazer o email depois
  validates :email, :presence => true, :uniqueness => true,:confirmation => true
  validates :alternate_email, :format => { :with => %r{^((?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4}))?$}i}

  validates :name, :presence => true,:length => { :within => 6.. 60}
  validates :birthdate, :presence => true
  validates :cpf, :presence => true, :uniqueness => true

  validates :address, :presence => true
  validates :address_number, :presence =>true
  validates :address_neighborhood, :presence =>true
  validates :zipcode, :presence =>true

  validates :country, :presence =>true
  validates :state, :presence =>true
  validates :city, :presence =>true
  validates :institution, :presence =>true

  #  validates :terms, :acceptance => true
  #  validates :password, :confirmation => true
  #  validates :username, :exclusion => { :in => %w(admin superuser) }
  #  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create }
  #  validates :age, :inclusion => { :in => 0..9 }
  #  validates :first_name, :length => { :maximum => 30 }
  #  validates :age, :numericality => true
  #  validates :username, :presence => true
  #  validates :username, :uniqueness => true

  #validaçao do CPF
  usar_como_cpf :cpf

  validate :cpf_ok
  def cpf_ok
    cpf_verify = Cpf.new(self[:cpf])
    errors.add(:cpf, I18n.t(:new_user_msg_cpf_error)) unless cpf_verify.valido?
  end

	#Detalhes da Senha #
  acts_as_authentic do |c|
		#c.require_password_confirmation = false
		#c.validates_length_of_password_field_options = {:minimum => 3}
    c.validate_email_field = false
    c.validate_login_field = false
    c.validate_password_field = false
		c.crypto_provider = CryptoProvider
	end

  # Configuração do paperclip para upload de fotos
  has_attached_file :photo,
    :styles => {
      :medium => "72x90#",
      :small => "24x30#"
    },
    :path => ":rails_root/public/images/:class/:id/:style_:basename.:extension",
    :url => "/images/:class/:id/:style_:basename.:extension",
    :default_url => "/images/no_image.png"

  # paperclip uses: file_name, content_type, file_size e updated_at

  #path and URL define that images will be in "public/images/"
  #  and will be created a folder called "users" with object id (eg users/1)
  #default_url define default image (if image is dropped or not exists)

  #  validates_attachment_presence :photo
  validates_attachment_size :photo, :less_than=>700.kilobyte, :message => " " # Esse :message => " " deve permanecer dessa forma enquanto não descobrirmos como passar a mensagem de forma correta. Se o message for vazio a validação não é feita.
  validates_attachment_content_type :photo, :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg'], :message => :invalid_type

end
