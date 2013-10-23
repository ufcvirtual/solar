class User < ActiveRecord::Base

  has_one :personal_configuration

  has_many :allocations
  has_many :allocation_tags, :through => :allocations, :uniq => true
  has_many :profiles, :through => :allocations, :uniq => true, conditions: { profiles: {status: true}, allocations: {status: 1} } # allocation.status = Allocation_Activated
  has_many :logs
  has_many :lessons
  has_many :discussion_posts, class_name: "Post", foreign_key: "user_id"
  has_many :user_messages
  has_many :message_labels
  has_many :assignment_files
  has_many :user_contacts, class_name: "UserContact", foreign_key: "user_id"
  has_many :user_contacts, class_name: "UserContact", foreign_key: "user_related_id"
  has_many :chat_messages

  after_create :basic_profile_allocation

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :timeoutable and :omniauthable, :trackable
  devise :database_authenticatable, :registerable, :validatable,
    :recoverable, :encryptable, :token_authenticatable # autenticacao por token

  before_save :ensure_authentication_token!, :downcase_username

  @has_special_needs

  attr_accessible :username, :email, :email_confirmation, :alternate_email, :password, :password_confirmation, :remember_me, :name, :nick, :birthdate,
    :address, :address_number, :address_complement, :address_neighborhood, :zipcode, :country, :state, :city,
    :telephone, :cell_phone, :institution, :gender, :cpf, :bio, :interests, :music, :movies, :books, :phrase, :site, :photo,
    :special_needs

  attr_accessor :login, :has_special_needs

  email_format = %r{^((?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4}))?$}i # regex para validacao de email

  validates :cpf, presence: true, uniqueness: true
  validates :name, presence: true, length: { :within => 6..90 }
  validates :nick, presence: true, length: { :within => 3..34 }
  validates :birthdate, presence: true
  validates :username, presence: true, :length => { :within => 3..20 }, :uniqueness => true
  validates :password, presence: true, confirmation: true, unless: Proc.new { |a| a.password.blank? }
  validates :alternate_email, :format => { :with => email_format }
  validates :email, presence: true, confirmation: true, :format => { :with => email_format }, if: Proc.new {|a| a.email_changed? }
  validates :special_needs, presence: true, :if => :has_special_needs?

  validates_length_of :address, :maximum => 99
  validates_length_of :address_neighborhood, :maximum => 49
  validates_length_of :zipcode, :maximum => 9
  validates_length_of :country,:maximum => 90
  validates_length_of :city, :maximum => 90
  validates_length_of :institution, :maximum => 120

  validate :cpf_ok, :unless => :already_cpf_error?

  # paperclip uses: file_name, content_type, file_size e updated_at
  # Configuração do paperclip para upload de fotos
  has_attached_file :photo,
    :styles => { :medium => "72x90#", :small => "25x30#", :forum => "40x40#" },
    :path => ":rails_root/media/:class/:id/photos/:style.:extension",
    :url => "/media/:class/:id/photos/:style.:extension",
    :default_url => "/assets/no_image_:style.png"

  validates_attachment_size :photo, :less_than => 700.kilobyte, :message => " " # Esse :message => " " deve permanecer dessa forma enquanto não descobrirmos como passar a mensagem de forma correta. Se o message for vazio a validação não é feita.
  validates_attachment_content_type :photo,
    :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg'],
    :message => :invalid_type

  default_scope :order => 'name ASC'

  #Garantindo que o cpf nao será salvo com os separadores.
  #  def cpf=(value)
  #    self[:cpf] = value.gsub(/\D/, '')
  #  end

  ##
  # Verifica se o radio_button escolhido na view é verdadeiro ou falso. 
  # Este método também define as necessidades especiais como sendo vazia caso a pessoa tenha selecionado que não as possui
  ##
  def has_special_needs?
    self.special_needs = "" unless @has_special_needs
    @has_special_needs
  end

  ##
  # Verifica se já existe um erro no campo de email ou, caso esteja na edição de usuário, verifica se o email foi alterado.
  # Caso o email não tenha sido alterado, não há necessidade de verificar sua confirmação
  ##
  def already_email_error_or_email_not_changed?
    (errors[:email].any? || !email_changed?)
  end

  def already_cpf_error?
    errors[:cpf].any?
  end

  ##
  # Permite modificação dos dados do usuário sem necessidade de informar a senha - para usuários já logados
  # Define o valor de @has_special_needs na edição de um usuário (update)
  ##
  def update_with_password(params={})
    @has_special_needs = (params[:has_special_needs] == 'true')
    params.delete(:has_special_needs)
    if (params[:password].blank? && params[:current_password].blank? && params[:password_confirmation].blank?)
      params.delete(:current_password)
      self.update_without_password(params)
    else
      super(params)
    end
  end

  ##
  # Este método define os atributos na hora de criar um objeto. Logo, redefine os atributos já existentes e define
  # o valor de @has_special_needs a partir do que é passado da página na criação de um usuário (create)
  ##
  def initialize(attributes = {})
     super(attributes)
     @has_special_needs = (attributes[:has_special_needs] == 'true')
  end

  def cpf_ok
    cpf_verify = Cpf.new(self[:cpf])
    errors.add(:cpf, I18n.t(:new_user_msg_cpf_error)) unless cpf_verify.valido? unless cpf_verify.nil?
  end

  ## Na criação, o usuário recebe o perfil de usuario basico
  def basic_profile_allocation
    new_allocation_user = Allocation.new :profile_id => Profile.find_by_types(Profile_Type_Basic).id, :status => Allocation_Activated, :user_id => self.id
    new_allocation_user.save!
  end

  def ensure_authentication_token!
    reset_authentication_token! if authentication_token.blank? 
  end

  def downcase_username
    self.username = self.username.downcase
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["translate(cpf,'.-','') = :value OR lower(username) = :value", { :value => login.strip.downcase }]).first
  end

  def groups(profile_id = nil, status = nil, curriculum_unit_id = nil, curriculum_unit_type_id = nil)
    query = []
    query << "allocations.status = #{status}" unless status.nil?
    query << "allocations.profile_id = #{profile_id}" unless profile_id.nil?
    query << "curriculum_units.id = #{curriculum_unit_id}" unless curriculum_unit_id.nil?
    query << "curriculum_unit_types.id = #{curriculum_unit_type_id}" unless curriculum_unit_type_id.nil?

    allocations.includes(allocation_tag: [group: [offer: [curriculum_unit: :curriculum_unit_type]]]).where(query.join(" AND ")).delete_if {|allocation| allocation.allocation_tag.nil? }.map(&:groups).flatten.compact.uniq
  end

  def profiles_activated(only_id = false)
    profiles = self.profiles.where("allocations.status = ?", Allocation_Activated).uniq
    return (only_id) ? profiles.map(&:id) : profiles
  end

  def profiles_with_access_on(action, controller, allocation_tag_id = nil, only_id = false)
    if allocation_tag_id.nil?
      profiles = self.profiles.
        joins(permissions_resources: :resource).
        where(
          resources: {action: action, controller: controller}).
        order("profiles.id DESC")
    else
      profiles = self.profiles.
        joins(permissions_resources: :resource).
        where(
          allocations: { allocation_tag_id: allocation_tag_id }, 
          resources: {action: action, controller: controller}).
        order("profiles.id DESC")
    end

    return (only_id) ? profiles.map { |p| p.id.to_i } : profiles
  end

  # Retorna os ids das allocations_tags ativadas de um usuário
  def activated_allocation_tag_ids(related = true)
    map = related ? "related" : "id"
    allocation_tags.where(allocations: {status: Allocation_Activated.to_i}).map(&map.to_sym).flatten.uniq
  end

  def active_for_authentication?
    super and self.active
  end

  def inactive_message
    I18n.t(:user_cannot_login)
  end

end
