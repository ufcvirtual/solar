class User < ActiveRecord::Base

  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, to: :ability

  CHANGEABLE_FIELDS = %W{bio interests music movies books phrase site nick alternate_email photo_file_name photo_content_type photo_file_size photo_updated_at active}
  MODULO_ACADEMICO  = YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s] rescue nil

  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner

  has_one :personal_configuration

  has_many :allocations
  has_many :allocation_tags, through: :allocations, uniq: true
  has_many :profiles, through: :allocations, uniq: true, conditions: { profiles: {status: true}, allocations: {status: 1} } # allocation.status = Allocation_Activated
  has_many :log_access
  has_many :log_actions
  has_many :lessons
  has_many :discussion_posts, class_name: "Post", foreign_key: "user_id"
  has_many :user_messages
  has_many :message_labels
  has_many :assignment_files
  has_many :chat_messages

  # has_many :user_contacts, class_name: "UserContact", foreign_key: "user_id"
  has_many :user_contacts, class_name: "UserContact", foreign_key: "user_related_id"

  after_create :basic_profile_allocation

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :timeoutable and :omniauthable, :trackable
  devise :database_authenticatable, :registerable, :validatable,
    :recoverable, :encryptable, :token_authenticatable # autenticacao por token

  before_save :ensure_authentication_token!, :downcase_username, :remove_mask_from_cpf

  @has_special_needs

  attr_accessible :username, :email, :email_confirmation, :alternate_email, :password, :password_confirmation, :remember_me, :name, :nick, :birthdate,
    :address, :address_number, :address_complement, :address_neighborhood, :zipcode, :country, :state, :city,
    :telephone, :cell_phone, :institution, :gender, :cpf, :bio, :interests, :music, :movies, :books, :phrase, :site, :photo,
    :special_needs, :active, :allocations_attributes, :integrated, :encrypted_password

  attr_accessor :login, :has_special_needs, :synchronizing

  email_format = %r{\A((?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4}))?\z}i

  validates :cpf, presence: true, uniqueness: true
  validates :name, presence: true, length: { within: 6..90 }
  validates :nick, presence: true, length: { within: 3..34 }
  validates :birthdate, presence: true
  validates :username, presence: true, length: { within: 3..20 }, uniqueness: true
  validates :password, presence: true, confirmation: true, unless: Proc.new { |a| a.password.blank? or ((not(MODULO_ACADEMICO.nil?) and MODULO_ACADEMICO["integrated"]) and a.integrated)}
  validates :alternate_email, format: { with: email_format }
  validates :email, presence: true, confirmation: true, uniqueness: true, format: { with: email_format }, unless: Proc.new {|a| a.already_email_error_or_email_not_changed? }
  validates :special_needs, presence: true, if: :has_special_needs?

  validates_length_of :address_neighborhood, maximum: 49
  validates_length_of :zipcode, maximum: 9
  validates_length_of :country, :city, :address ,maximum: 90
  validates_length_of :institution, maximum: 120

  validate :unique_cpf, if: "cpf_changed?"
  validate :integration, if: Proc.new{ |a| !a.new_record? and (not(MODULO_ACADEMICO.nil?) and MODULO_ACADEMICO["integrated"]) and a.integrated and (a.synchronizing.nil? or not(a.synchronizing))}
  validate :data_integration, if: Proc.new{ |a| (not(MODULO_ACADEMICO.nil?) and MODULO_ACADEMICO["integrated"]) and (a.new_record? or username_changed? or email_changed? or cpf_changed?) and (a.synchronizing.nil? or not(a.synchronizing)) }
  validate :cpf_ok, unless: :already_cpf_error?

  # paperclip uses: file_name, content_type, file_size e updated_at
  # Configuração do paperclip para upload de fotos
  has_attached_file :photo,
    styles: { medium: "72x90#", small: "25x30#", forum: "40x40#" },
    path: ":rails_root/media/:class/:id/photos/:style.:extension",
    url: "/media/:class/:id/photos/:style.:extension",
    default_url: "/assets/no_image_:style.png"

  validates_attachment_size :photo, less_than: 700.kilobyte, message: " " # Esse :message => " " deve permanecer dessa forma enquanto não descobrirmos como passar a mensagem de forma correta. Se o message for vazio a validação não é feita.
  validates_attachment_content_type :photo,
    content_type: ['image/jpeg','image/png','image/gif','image/pjpeg'],
    message: :invalid_type

  default_scope order: 'name ASC'

  ##
  # Verifica se o radio_button escolhido na view é verdadeiro ou falso. 
  # Este método também define as necessidades especiais como sendo vazia caso a pessoa tenha selecionado que não as possui
  ##
  def has_special_needs?
    self.special_needs = "" unless @has_special_needs or integrated
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

  def unique_cpf
    cpf_to_check = cpf_without_mask(cpf)
    cpf_of_user = cpf_without_mask(User.find(id).cpf) rescue ''

    users = User.where(cpf: cpf_to_check) if new_record? or cpf_to_check != cpf_of_user

    errors.add(:cpf, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) unless users.nil? or users.empty?
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
    errors.add(:cpf, I18n.t(:new_user_msg_cpf_error)) if not(cpf_verify.nil?) and not(cpf_verify.valido?)
  end

  ## Na criação, o usuário recebe o perfil de usuario basico
  def basic_profile_allocation
    new_allocation_user = Allocation.new profile_id: Profile.find_by_types(Profile_Type_Basic).id, status: Allocation_Activated, user_id: self.id
    new_allocation_user.save!
  end

  def ensure_authentication_token!
    reset_authentication_token! if authentication_token.blank?
  end

  def downcase_username
    self.username = self.username.downcase
  end

  def remove_mask_from_cpf
    self.cpf = cpf_without_mask(self.cpf)
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login      = conditions.delete(:login)
    where(conditions).where(["translate(cpf,'.-','') = :value OR lower(username) = :value", { value: login.strip.downcase }]).first
  end

  def groups(profile_id = nil, status = nil, curriculum_unit_id = nil, curriculum_unit_type_id = nil)
    query = []
    query << "allocations.status = #{status}"                        unless status.nil?
    query << "allocations.profile_id = #{profile_id}"                unless profile_id.nil?
    query << "curriculum_units.id = #{curriculum_unit_id}"           unless curriculum_unit_id.nil?
    query << "curriculum_unit_types.id = #{curriculum_unit_type_id}" unless curriculum_unit_type_id.nil?

    allocations.includes(allocation_tag: [group: [offer: {curriculum_unit: :curriculum_unit_type}]]).where(query.join(" AND ")).map(&:groups).compact.flatten
  end

  def profiles_activated(only_id = false)
    profiles = self.profiles.where("allocations.status = ?", Allocation_Activated).uniq
    return (only_id) ? profiles.map(&:id) : profiles
  end

  def profiles_with_access_on(action, controller, allocation_tag_id = nil, only_id = false)
    if allocation_tag_id.nil?
      profiles = self.profiles.joins(:resources).
        where(resources: {action: action, controller: controller}).
        order("profiles.id DESC")
    else
      profiles = self.profiles.joins(:resources).
        where(allocations: { allocation_tag_id: allocation_tag_id }, resources: {action: action, controller: controller}).
        order("profiles.id DESC")
    end

    return (only_id) ? profiles.map { |p| p.id.to_i } : profiles
  end

  # Retorna os ids das allocations_tags ativadas de um usuário
  def activated_allocation_tag_ids(related = true, interacts = false)
    map   = related   ? "related" : "id"
    query = interacts ? "cast(profiles.types & #{Profile_Type_Student} as boolean) OR cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)" : ""

    allocations.joins(:profile).where(allocations: {status: Allocation_Activated.to_i}).where(query).map(&:allocation_tag).compact.map(&map.to_sym).flatten.uniq
  end

  # Returns all allocation_tags_ids with activated access on informed actions of controller
  def allocation_tags_ids_with_access_on(actions, controller, all = false)
    allocations_tags = allocations.joins(profile: :resources)
      .where(resources: {action: actions, controller: controller}, status: Allocation_Activated)
      .select("DISTINCT allocation_tag_id").map(&:allocation_tag).compact
    allocations_tags.map{|at| (all ? at.related : at.related({lower: true}))}.flatten.uniq
  end

  # Returns user resources list as [{controller: :action}, ...] at informed allocation_tags_ids
  def resources_by_allocation_tags_ids(allocation_tags_ids)
    allocation_tags_ids = AllocationTag.where(id: allocation_tags_ids.split(" ")).map{|at| at.related(upper: true)}.flatten.uniq
    profiles.joins(:resources).where("allocations.allocation_tag_id IN (?) AND allocations.status = ?", allocation_tags_ids, Allocation_Activated)
      .map(&:resources).compact.flatten.map{|resource| 
        {resource.controller.to_sym => resource.action.to_sym}
      }
  end

  def active_for_authentication?
    super and self.active
  end

  def inactive_message
    I18n.t(:user_cannot_login)
  end

  # faltando pegar apenas alocacoes validas
  def all_allocation_tags(objects = false)
    allocation_tags.map {|at| at.related(all: true, objects: objects)}.flatten.uniq
  end

  def status
    active ? I18n.t(:active) : I18n.t(:blocked)
  end

  def to_msg
    {
      id: id,
      name: name,
      email: email,
      resume: "#{name} <#{email}>"
    }
  end

  ## import users from csv file
  def self.import(file, sep = ";")
    imported = []
    log = {error: [], success: []}
    csv = Roo::CSV.new(file.path, csv_options: {col_sep: sep})
    header = csv.row(1)

    raise I18n.t(:invalid_file, scope: [:administrations, :import_users]) unless header.join(';') == YAML::load(File.open("config/global.yml"))[Rails.env.to_s]["import_users"]["header"]

    (2..csv.last_row).each do |i|
      row = Hash[[header, csv.row(i)].transpose]

      user_exist = where(cpf: row['cpf']).first
      user = user_exist.nil? ? new : user_exist

      unless user.integrated
        user.attributes = row.to_hash.slice(*accessible_attributes)

        user.username = user.cpf if user.username.nil?
        user.nick = user.username if user.nick.nil?
        user.birthdate = "1970-01-01" if user.birthdate.nil? # verificar este campo
        user.password = "123456" if user.password.nil?
      end
      user.active = true

      if user.save
        log[:success] << I18n.t(:success, scope: [:administrations, :import_users, :log], cpf: user.cpf)
        imported << user
      else
        log[:error] << I18n.t(:error, scope: [:administrations, :import_users, :log], cpf: user.cpf, error: user.errors.full_messages.compact.uniq.join(", "))
      end
    end ## each

    {imported: imported, log: log}
  end

  def is_admin?
    (not allocations.joins(:profile).where("cast(types & #{Profile_Type_Admin} as boolean) AND allocations.status = #{Allocation_Activated}").empty?)
  end

  def self.all_at_allocation_tags(allocation_tags_ids, status = Allocation_Activated)
    joins(:allocations).where(allocations: {status: status, allocation_tag_id: allocation_tags_ids}).select("DISTINCT users.id").select("users.name, users.email")
  end

  ### integration MA ###

  def integration
    changed_fields = (changed - CHANGEABLE_FIELDS)
    errors.add(changed_fields.first.to_sym, I18n.t("users.errors.ma.only_by")) if changed_fields.size > 0
  end

  # chamada para MA verificando se existe usuário com o login, cpf ou email informados
  def data_integration
    user_cpf = cpf.delete('.').delete('-')
    self.connect_and_validates_user
  rescue HTTPClient::ConnectTimeoutError => error # if MA don't respond (timeout)
    errors.add(:username, I18n.t("users.errors.ma.cant_connect")) if username_changed?
    errors.add(:cpf, I18n.t("users.errors.ma.cant_connect"))      if cpf_changed?
    errors.add(:email, I18n.t("users.errors.ma.cant_connect"))    if email_changed?
  rescue => error
    errors.add(:base, I18n.t("users.errors.ma.problem_accessing"))
  ensure
    errors_messages = errors.full_messages
    # if is new user and happened some problem connecting with MA
    if new_record? and (errors_messages.include?(I18n.t("users.errors.ma.cant_connect")) or errors_messages.include?(I18n.t("users.errors.ma.problem_accessing")))
      tmp_email       = [user_cpf, MODULO_ACADEMICO["tmp_email_provider"]].join("@")
      self.attributes = {username: user_cpf, email: tmp_email, email_confirmation: tmp_email} # set username and invalid email
      user_errors     = errors.messages.to_a.collect{|a| a[1]}.flatten.uniq # all errors
      ma_errors       = I18n.t("users.errors.ma").to_a.collect{|a| a[1]}    # ma errors
      if (user_errors - ma_errors).empty? # form doesn't have other errors
        errors.clear # clear ma errors
      else # form has other errors
        errors.add(:username, I18n.t("users.errors.ma.login"))
        errors.add(:email, I18n.t("users.errors.ma.email"))
      end
    end
  end

  # user result from validation MA method
  # receives the response and the WS client
  def self.validate_user_result(result, client, cpf, user = nil)
    unless result.nil?
      result = result[:int]
      if result.include?("6") # unavailable cpf, thus already in use by MA
        user_data = User.connect_and_import_user(cpf, client)
        unless user_data.nil? # if user exists
          # verify if cpf, username or email already exists
          unless User.find_by_cpf(user_data[0]) or User.find_by_username(user_data[5]) or User.find_by_email(user_data[8])
            ma_attributes = User.user_ma_attributes(user_data) # import all data from MA user
            (user.nil? ? (user = User.new(ma_attributes)) : (user.attributes = ma_attributes))
            user.errors.clear # clear all errors, so the system can import and save user's data 
            return user.save(validate: false) if user.new_record? # if user don't exist, saves it without validation (all necessary data must come from MA)
          else
            cpf_user = User.find_by_cpf(user_data[0])
            cpf_user.synchronize(user_data) unless cpf_user.nil? # if exists user with the same cpf, synchronize data
          end
        else
          return nil
        end
      else
        return nil if user.nil? # if user don't exist yet
        user.errors.add(:username, I18n.t("users.errors.ma.already_exists")) if result.include?("1")  # unavailable login/username, thus already in use by MA
        user.errors.add(:username, I18n.t("users.errors.invalid"))           if result.include?("2")  # invalid login/username
        user.errors.add(:password, I18n.t("users.errors.invalid"))           if result.include?("3")  # invalid password
        user.errors.add(:email, I18n.t("users.errors.ma.already_exists"))    if result.include?("4")  # unavailable email, thus already in use by MA
        user.errors.add(:email, I18n.t("users.errors.invalid"))              if result.include?("5")  # invalid email
        user.errors.add(:cpf, I18n.t("users.errors.invalid"))                if result.include?("7")  # invalid cpf
        user.errors.add(:base, I18n.t("users.errors.ma.problem_accessing"))  if result.include?("99") # unknown error
      end
    end
  end

  # synchronizes user data with MA data
  def synchronize(user_data = nil)
    user_data = User.connect_and_import_user(cpf) if user_data.nil?
    unless user_data.nil? # if user exists
      ma_attributes = User.user_ma_attributes(user_data)
      errors.clear # clear all errors, so the system can import and save user's data 
      self.synchronizing = true
      update_attributes(ma_attributes)
      self.synchronizing = false
      return true
    else
      return nil
    end
  rescue => errors
    return false
  end

  def self.user_ma_attributes(user_data)
    {name: user_data[2], cpf: user_data[0], birthdate: user_data[3], gender: (user_data[4] == "M"), cell_phone: user_data[17], 
      nick: (user_data[7].nil? ? ([user_data[2].split(" ")[0], user_data[2].split(" ")[1]].join(" ")) : user_data[7]), telephone: user_data[18], 
      special_needs: (user_data[19].downcase == "nenhuma" ? nil : user_data[19]), address: user_data[10], address_number: user_data[11], zipcode: user_data[13],
      address_neighborhood: user_data[12], country: user_data[16], state: user_data[15], city: user_data[14], username: (user_data[5].blank? ? user_data[0] : user_data[5]),
      encrypted_password: user_data[6], password: user_data[6], email: (user_data[8].blank? ? [user_data[0], MODULO_ACADEMICO["tmp_email_provider"]].join("@") : user_data[8]), integrated: true} #, enrollment_code: user_data[19] # user is set as integrated
  end

  def connect_and_validates_user
    user_cpf = cpf_without_mask(cpf)

    client   = Savon.client wsdl: MODULO_ACADEMICO["wsdl"]
    response = client.call MODULO_ACADEMICO["methods"]["user"]["validate"].to_sym, message: {cpf: user_cpf, email: email, login: username } # gets user validation

    User.validate_user_result(response.to_hash[:validar_usuario_response][:validar_usuario_result], client, user_cpf, self)
  end

  def self.connect_and_import_user(cpf, client = nil)
    client    = Savon.client wsdl: MODULO_ACADEMICO["wsdl"] if client.nil?
    response  = client.call(MODULO_ACADEMICO["methods"]["user"]["import"].to_sym, message: { cpf: cpf.delete('.').delete('-') }) # import user
    user_data = response.to_hash[:importar_usuario_response][:importar_usuario_result]
    return (user_data.nil? ? nil : user_data[:string])
  end

  def integrated?
    (not(MODULO_ACADEMICO.nil?) and MODULO_ACADEMICO["integrated"]) and integrated
  end

  private

    def cpf_without_mask(cpf)
      cpf.gsub(/[.-]/, '')
    end

end
