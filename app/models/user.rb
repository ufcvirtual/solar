class User < ActiveRecord::Base

  include PersonCpf

  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, to: :ability

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  CHANGEABLE_FIELDS = %W{bio interests music movies books phrase site nick alternate_email photo_file_name photo_content_type photo_file_size photo_updated_at active}
  MODULO_ACADEMICO  = YAML::load(File.open('config/modulo_academico.yml'))[Rails.env.to_s] rescue nil

  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner

  has_one :personal_configuration

  has_many :allocations
  has_many :allocation_tags, -> { uniq }, through: :allocations
  has_many :profiles, -> { where(profiles: { status: true }, allocations: { status: 1 }).uniq }, through: :allocations # allocation.status = Allocation_Activated
  has_many :log_access
  has_many :log_actions
  has_many :lessons
  has_many :discussion_posts, class_name: 'Post', foreign_key: 'user_id'
  has_many :user_messages
  has_many :message_labels
  has_many :assignment_files
  has_many :questions
  has_many :academic_allocation_users
  has_many :chat_messages
  has_many :public_files
  has_many :user_contacts, foreign_key: 'user_related_id'
  has_many :lesson_notes
  has_many :questions
  has_many :up_questions, class_name: 'Question', foreign_key: 'updated_by_user_id'
  has_many :log_navigations

  has_and_belongs_to_many :notifications, join_table: 'read_notifications'

  after_create :basic_profile_allocation

  devise :database_authenticatable, :registerable, :recoverable, :encryptable#, :timeoutable, :validatable

  before_save :ensure_authentication_token!, :downcase_username
  before_save :downcase_email, unless: 'email.blank?'
  after_save :log_update_user
  after_save :update_digital_class_user, if: '(!new_record? && (name_changed? || email_changed? || cpf_changed?) && !digital_class_user_id.nil?)', on: :update

  before_save :set_previous, if: '(!new_record? && ((username_changed? && !previous_username.blank?) || email_changed? && !previous_email.blank?)) && (!synchronizing)'

  @has_special_needs

  attr_accessor :login, :has_special_needs, :synchronizing

  email_format = %r{\A((?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4}))?\z}i

  validates :name, presence: true, length: { within: 6..200 }
  validates :nick, presence: true, length: { within: 3..34 }
  validates :birthdate, presence: true
  validates :username, presence: true, length: { maximum: 20, minimum: 3 }, uniqueness: {case_sensitive: false}, format: { with: /\A[_.a-zA-Z0-9\-]+\Z/ }, unless: Proc.new{ |a| !a.on_blacklist? && a.integrated? && (a.synchronizing.nil? || a.synchronizing) }

  validates :password, presence: true, confirmation: true, length: { minimum: 6, maximum: 120 }, unless: Proc.new { |a| !a.encrypted_password.blank? || (a.integrated? && !a.on_blacklist?) }
  # validates :alternate_email, format: { with: email_format }, uniqueness: {case_sensitive: false}, unless: 'alternate_email.blank?'
  validates :email, presence: true, format: { with: email_format }, unless: Proc.new { |a| (a.integrated && !a.on_blacklist?)}

  validates :email, uniqueness: {case_sensitive: false}, unless: Proc.new { |a| (a.integrated && !a.on_blacklist?) || a.email.blank?}

  validates :email, confirmation: true, if: "(email_changed? || new_record?) && !(integrated && !on_blacklist?)"

  validates :special_needs, presence: true, if: :has_special_needs?

  validates_length_of :address_neighborhood, maximum: 49
  validates_length_of :zipcode, maximum: 9
  validates_length_of :country, :city, maximum: 90
  validates_length_of :address ,maximum: 150
  validates_length_of :institution, maximum: 120
  validates_length_of :cell_phone, maximum: 100
  validates_length_of :telephone, maximum: 50
  validates_length_of :email, maximum: 200

  validate :integration, if: Proc.new{ |a| !a.new_record? && !a.on_blacklist? && a.integrated? && (a.synchronizing.nil? || !a.synchronizing) }
  validate :data_integration, if: Proc.new{ |a| (!MODULO_ACADEMICO.nil? && MODULO_ACADEMICO["integrated"]) && (a.new_record? || username_changed? || email_changed? || cpf_changed?) && (a.synchronizing.nil? || !a.synchronizing) }

  validate :unique_cpf, if: "cpf_changed?"
  validate :login_differ_from_cpf
  validate :only_admin, if: '!new_record? && (cpf_changed? || active_changed?)'

  before_save :set_empty_email, if: 'email.blank?'

  # paperclip uses: file_name, content_type, file_size e updated_at
  has_attached_file :photo,
    styles: { medium: '120x120#', small: '30x30#', forum: '40x40#' },
    path: ':rails_root/media/:class/:id/photos/:style.:extension',
    url: '/media/:class/:id/photos/:style.:extension',
    default_url: '/assets/no_image_:style.png'

  validates_attachment_size :photo, less_than: 700.kilobyte, message: '' # Esse message vazio deve permanecer dessa forma enquanto nao descobrirmos como passar a mensagem de forma correta. Se o message for vazio a validacao nao eh feita.
  validates_attachment_content_type :photo,
    content_type: ['image/jpeg', 'image/png', 'image/gif', 'image/pjpeg'],
    message: :invalid_type

  #default_scope order: 'users.name ASC'

  def order
   'users.name ASC'
  end
  ## Este metodo define os atributos na hora de criar um objeto. Logo, redefine os atributos ja existentes e define
  ## o valor de has_special_needs a partir do que eh passado da pagina na criacao de um usuario (create)
  def initialize(attributes = {})
    super(attributes)
    @has_special_needs = (attributes[:has_special_needs] == 'true')
  end

  # devise

  def ensure_authentication_token!
    reset_authentication_token! if authentication_token.blank?
  end

  def active_for_authentication?
    super and self.active
  end

  ## Permite modificacao dos dados do usuario sem necessidade de informar a senha - para usuarios ja logados
  ## Define o valor de @has_special_needs na edicao de um usuario (update)
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

  ## metodos de validacoes

  def only_admin
    errors.add(:base, I18n.t('users.errors.cpf_admin')) unless User.current.admin?
  end

  def log_update_user
    LogAction.create(log_type: LogAction::TYPE[:update], user_id: id, description: "update_me: #{attributes.except('encrypted_password', 'reset_password_token', 'password_salt', 'authentication_token')} ")
  end
  ## Verifica se o radio_button escolhido na view eh verdadeiro ou falso.
  ## Este metodo tambem define as necessidades especiais como sendo vazia caso a pessoa tenha selecionado que nao as possui
  def has_special_needs?
    self.special_needs = '' unless @has_special_needs || integrated
    @has_special_needs
  end

  def unique_cpf
    cpf_to_check = self.class.cpf_without_mask(cpf)
    cpf_of_user  = self.class.cpf_without_mask(User.find(id).cpf) rescue ''

    users = User.where(cpf: cpf_to_check) if new_record? || cpf_to_check != cpf_of_user

    errors.add(:cpf, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) unless users.nil? || users.empty?
  end

  def inactive_message
    I18n.t(:user_cannot_login)
  end

  def admin?
    allocations.joins(:profile).where("cast(types & #{Profile_Type_Admin} as boolean) AND allocations.status = #{Allocation_Activated}").any?
  end

  def editor?
    allocations.joins(:profile).where("cast(types & #{Profile_Type_Editor} as boolean) AND allocations.status = #{Allocation_Activated}").any?
  end

  # if user is only researcher, must not see any information about users
  def is_researcher?(allocation_tags_ids)
    all = Profile.find_by_sql <<-SQL
      SELECT COUNT(*) FROM
        (
          SELECT DISTINCT profiles.id
          FROM profiles
          JOIN allocations ON allocations.profile_id = profiles.id
          WHERE
            allocations.allocation_tag_id IN (#{allocation_tags_ids.join(',')})
            AND
            user_id = #{id}
            AND
            allocations.status = #{Allocation_Activated}
        ) AS ids;

    SQL

    researcher_profiles = profiles_with_access_on('cant_see_info', 'users', allocation_tags_ids, false, true)
    (all.first['count'].to_i != 0 && all.first['count'] == researcher_profiles.first['count'])
  end

  def is_student?(allocation_tags_ids)
    all = Profile.find_by_sql <<-SQL
      SELECT COUNT(*) FROM
        (
          SELECT DISTINCT profiles.id
          FROM profiles
          JOIN allocations ON allocations.profile_id = profiles.id
          WHERE
            allocations.allocation_tag_id IN (#{allocation_tags_ids.join(',')})
            AND
            user_id = #{id}
            AND
            allocations.status = #{Allocation_Activated}
            AND
            cast( profiles.types & '#{Profile_Type_Student}' as boolean )
        ) AS ids;

    SQL
    (all.first['count'].to_i != 0)
  end

  def set_previous
    self.previous_username = nil if username_changed? && !previous_username.blank?
    self.previous_email = nil if email_changed? && !previous_email.blank?
  end

  def set_previous
    self.previous_username = nil if username_changed? && !previous_username.blank?
    self.previous_email = nil if email_changed? && !previous_email.blank?
  end

  ## Na criação, o usuário recebe o perfil de usuario basico
  def basic_profile_allocation
    Allocation.create profile_id: Profile.find_by_types(Profile_Type_Basic).id, status: Allocation_Activated, user_id: self.id
  end

  def downcase_username
    self.username = self.username.downcase
  end

  def downcase_email
    self.email = email.downcase
  end

  def status
    active ? I18n.t(:active) : I18n.t(:blocked)
  end

  # faltando pegar apenas alocacoes validas
  def all_allocation_tags(objects = false)
    allocation_tags.collect! { |at| RelatedTaggable.related(at) }.flatten.uniq
  end

  def to_msg
    {
      id: id,
      name: name,
      email: email,
      resume: "#{name} <#{email || I18n.t('messages.no_mail')}>"
    }
  end

  def groups(profiles_ids = [], status = nil, curriculum_unit_id = nil, curriculum_unit_type_id = nil, offer_id = nil, group_status = true, semester_id = nil)
    query = ['allocations.allocation_tag_id IS NOT NULL']
    query << "allocations.status = #{status}"                        unless status.blank?
    query << "allocations.profile_id IN (#{profiles_ids.join(',')})" unless profiles_ids.blank?
    ats = allocations.where(query.join(' AND ')).pluck(:allocation_tag_id)

    query = []
    query << "curriculum_unit_id = #{curriculum_unit_id}"            unless curriculum_unit_id.blank?
    query << "curriculum_unit_type_id = #{curriculum_unit_type_id}"  unless curriculum_unit_type_id.blank?
    query << "groups.offer_id = #{offer_id}"                         unless offer_id.blank?
    query << "offers.semester_id = #{semester_id}"                   unless semester_id.blank?
    query << "groups.status = #{group_status}"                       unless group_status.blank?
    Group.joins({offer: :semester}, :related_taggables).where('related_taggables.group_at_id IN (?) OR related_taggables.offer_at_id IN (?) OR related_taggables.course_at_id IN (?) OR related_taggables.curriculum_unit_at_id IN (?) OR related_taggables.curriculum_unit_type_at_id IN (?)', ats, ats, ats, ats, ats)
      .where(query.join(' AND '))
      .select('DISTINCT groups.id, semesters.*, groups.*').order('semesters.name DESC, groups.code ASC')
  end

  ## profiles: [], contexts: [], general_context: true, allocation_tag_id
  def menu_list(args = {})
    if args[:allocation_tag_id].present?
      at = AllocationTag.find(args[:allocation_tag_id]).related
      query_at = '(allocations.allocation_tag_id IN (?) OR allocations.allocation_tag_id IS NULL)'
    end

    user_profiles = profiles.where(query_at, at).pluck(:id)

    # sempre carrega contexto geral independente do perfil do usuario
    args = { profiles: [], contexts: [], general_context: true }.merge(args)
    args[:profiles] << user_profiles
    args[:contexts] << Context_General if args[:general_context]

    query_contexts = 'menus_contexts.context_id IN (:contexts)' unless args[:contexts].empty?
    resources_id = Resource.joins(:profiles).where(profiles: { id: args[:profiles].flatten })

    Menu.joins(:menus_contexts).includes(:resource, :parent).where(resource_id: resources_id, status: true)
      .where(query_contexts, contexts: args[:contexts]).order('parents_menus.order, menus.order')

  end

  def profiles_with_access_on(action, controller, allocation_tag_id = nil, only_id = false, count = false, verify_global_profile=false)
    sql = []
    sql << 'SELECT COUNT(*) FROM
        (' if count
    sql << (count || only_id ? 'SELECT DISTINCT profiles.id' : 'SELECT DISTINCT profiles.id, profiles.*')
    sql << "FROM profiles
          JOIN allocations ON allocations.profile_id = profiles.id
          JOIN permissions_resources ON permissions_resources.profile_id = profiles.id
          JOIN resources   ON resources.id = permissions_resources.resource_id
          WHERE
            allocations.user_id = #{id}
            AND
            resources.action = ?
            AND
            resources.controller = ?
            AND
            allocations.status = #{Allocation_Activated}"

    sql << " AND " if !allocation_tag_id.blank? || verify_global_profile

    query = []
    query << "(allocations.allocation_tag_id IN (#{allocation_tag_id.join(',')}))" unless allocation_tag_id.blank?
    query << "(allocations.allocation_tag_id IS NULL)" if verify_global_profile

    sql << "( #{query.join(' OR ')} )"  unless query.blank?

    sql << (count ? ') AS ids;' : ';')

    profiles = Profile.find_by_sql [sql.join(' '), action, controller]

    (only_id) ? profiles.map(&:id) : profiles
  end

  def self.with_access_on(action,controller,allocation_tags_ids, emails=false)
    query1 = (emails ? 'LEFT JOIN personal_configurations ON users.id = personal_configurations.user_id' : '')
    query2 = (emails ? ' AND (personal_configurations.academic_tool IS NULL OR personal_configurations.academic_tool=TRUE)' : '')

    User.find_by_sql <<-SQL
      SELECT users.id, email, cpf
      FROM users
      JOIN allocations ON allocations.user_id = users.id
      JOIN profiles ON allocations.profile_id = profiles.id
      JOIN permissions_resources ON permissions_resources.profile_id = profiles.id
      #{query1}
      JOIN resources   ON resources.id = permissions_resources.resource_id
      WHERE
        resources.action = '#{action}'
        AND
        resources.controller = '#{controller}'
        AND
        allocations.status = #{Allocation_Activated}
        AND
        (allocations.allocation_tag_id IN (#{allocation_tags_ids.join(',')}))
        #{query2}
    SQL
  end

  def get_allocation_tags_ids_from_profiles(responsible = true, observer = false)
    query = {
      status: Allocation_Activated,
      profiles: { status: true }
    }

    query_type = []
    query_type << 'cast(profiles.types & :responsible as boolean) OR cast(profiles.types & :coord as boolean)' if responsible
    query_type << 'cast(profiles.types & :observer as boolean)' if observer

    return false if query_type.empty?

    AllocationTag.where(id: allocations.joins(:profile).where(query)
      .where(query_type.join(' OR '), responsible: Profile_Type_Class_Responsible, observer: Profile_Type_Observer, coord: Profile_Type_Coord).map(&:allocation_tag_id))
      .map(&:related)
      .flatten
  end

  # Retorna os ids das allocations_tags ativadas de um usuário
  def activated_allocation_tag_ids(related = true, interacts = false)
    query = interacts ? "cast(profiles.types & #{Profile_Type_Student} as boolean) OR cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)" : ''
    allocation_tags = AllocationTag.joins(allocations: :profile).where(allocations: {user_id: id, status: Allocation_Activated.to_i}).where(query)
    (related ? allocation_tags.collect!{ |at| at.related }.flatten.uniq : allocation_tags.pluck(:id))
  end

  # Returns all allocation_tags_ids with activated access on informed actions of controller
  # if all is true         => recover all related
  # if include_nil is true => include nil if some allocation is not rellated to any allocation_tag
  def allocation_tags_ids_with_access_on(actions, controller, all=false, include_nil=false)
    allocations     = Allocation.joins(profile: :resources).where(resources: { action: actions, controller: controller }, allocations: { status: Allocation_Activated, user_id: id }).select('DISTINCT allocation_tag_id, allocations.id')
    allocation_tags = AllocationTag.joins(:allocations).where(allocations: { id: allocations.pluck(:id) }).pluck(:id)

    has_nil = (include_nil && allocations.where(allocation_tag_id: nil).any?)

    allocation_tags = RelatedTaggable.related_from_array_ats(allocation_tags.compact, (all ? {} : { lower: true }))
    allocation_tags << nil if has_nil
    allocation_tags
  end

  # Returns user resources list as [{controller: :action}, ...] at informed allocation_tags_ids
  def resources_by_allocation_tags_ids(allocation_tags_ids)
    allocation_tags_ids = RelatedTaggable.related_from_array_ats(allocation_tags_ids.split(' '), { upper: true })
    profiles.joins(:resources).where('allocations.allocation_tag_id IN (?) AND allocations.status = ?', allocation_tags_ids, Allocation_Activated)
      .map(&:resources).compact.flatten.map { |resource| { resource.controller.to_sym => resource.action.to_sym } }
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login      = conditions.delete(:login)
    where(conditions).where(["translate(cpf,'.-','') = :value OR lower(username) = :value", { value: login.strip.downcase }]).first
  end

  def self.all_at_allocation_tags(allocation_tags_ids, status = Allocation_Activated, interacts = false)
    query = []
    query <<  "(cast(profiles.types & #{Profile_Type_Student} as boolean) OR cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean))" if interacts
    query << "allocations.allocation_tag_id IN (#{allocation_tags_ids.join(',')})" unless allocation_tags_ids.blank?

    joins(allocations: :profile).where(active: true, allocations: { status: status }).where(query.join(' AND '))
      .select('DISTINCT users.id').select('users.name, users.email')
      .select('array_agg(DISTINCT profiles.name) profile_name, profiles.types').group('users.id, users.name, users.email, profiles.types')
  end

  # Searches all users which "type" column includes "text"
  # if allocation_tags_ids is informed and doesn't include nil => searches users allocated at the allocation_tags_ids
  def self.find_by_text_ignoring_characters(text, type = nil, allocation_tags_ids = [])
    if type.nil?
      name_or_cpf = text.delete(".").delete("-")
      users = where("lower(unaccent(name)) LIKE lower(unaccent(?)) OR lower(unaccent(cpf)) LIKE lower(unaccent(?)) OR lower(unaccent(email)) LIKE lower(unaccent(?))", "%#{name_or_cpf}%", "%#{name_or_cpf}%", "%#{text}%")
    else
      raise CanCan::AccessDenied unless %w[name email username cpf].include?(type)
      text = text.delete(".").delete("-") if %w[name cpf].include?(type)
      users = where("lower(unaccent(#{type})) LIKE lower(unaccent(?))", "%#{text}")
    end
    users = users.joins(:allocations).where("allocation_tag_id IN (?)", allocation_tags_ids) unless allocation_tags_ids.blank? || allocation_tags_ids.include?(nil)
    users.select('DISTINCT users.id').select('users.*').order('name')
  end

  ################################
  ## import users from csv file ##
  ################################

  def self.import(file, ats=nil)
    raise I18n.t(:invalid_file, scope: [:administrations, :import_users]) if (File.extname(file.original_filename) == '.csv')

    imported = []
    log = { error: [], success: [] }

    spreadsheet = open_spreadsheet(file, ';')
    header      = spreadsheet.row(1)

    raise I18n.t(:invalid_file, scope: [:administrations, :import_users]) unless (['.xlsx', '.xls', '.odt'].include?(File.extname(file.original_filename)) && (header & (YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['import_users']['header'].split(';'))).size == header.size)

    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      row = row.collect{ |k,v|
        if k == 'CPF' || k == 'Cpf'
          { k.try(:strip) => v }
        else
          { k.try(:strip) => (v.to_s.try(:strip) rescue '') }
        end
       }.reduce Hash.new, :merge

      cpf = (row['CPF'] || row['Cpf']).is_a?(String) ? (row['CPF'] || row['Cpf']).strip.delete('.').delete('-').rjust(11, '0') : (row['CPF'] || row['Cpf']).to_i.to_s.strip.rjust(11, '0')

      user_exist = where(cpf: cpf).first
      user = user_exist.nil? ? new(cpf: cpf) : user_exist
      user_data = nil
      if (!MODULO_ACADEMICO.nil? && MODULO_ACADEMICO['integrated'])
        user_data = User.connect_and_import_user(cpf) # try to import
        user.synchronize(user_data) # synchronize user with new MA data
      end

      if user_data.blank? || !user.selfregistration
        blacklist = UserBlacklist.where(cpf: user.cpf).first_or_initialize
        blacklist.name = (user.try(:name) || row['Nome']) if blacklist.new_record?
      end
      can_add_to_blacklist = !blacklist.nil? && (blacklist.valid? || !blacklist.new_record?)
      new_password         = nil
      group = Group.joins(:allocation_tag).where(allocation_tags: {id: ats}).where("lower(code) = ?", row['Turma'].downcase).first if (row.include?('Turma') && !row['Turma'].blank? && !ats.blank?)

      if !user.integrated || can_add_to_blacklist
        blacklist.save if !blacklist.nil? && blacklist.new_record? && user.integrated && can_add_to_blacklist

        params = {}
        params.merge!({ email: row['Email'].downcase })             if row.include?('Email') && !row['Email'].blank?
        params.merge!({ name: row['Nome'] })                        if row.include?('Nome') && !row['Nome'].blank?
        params.merge!({ address: row['Endereço'] })                 if row.include?('Endereço') && !row['Endereço'].blank?
        params.merge!({ country: row['País'] })                     if row.include?('País') && !row['País'].blank?
        params.merge!({ state: row['Estado'] })                     if row.include?('Estado') && !row['Estado'].blank?
        params.merge!({ city: row['Cidade'] })                      if row.include?('Cidade') && !row['Cidade'].blank?
        params.merge!({ institution: row['Instituição'] })          if row.include?('Instituição') && !row['Instituição'].blank?
        params.merge!({ cpf: cpf })                                 if row.include?('CPF') || row.include?('Cpf')
        params.merge!({ gender: (row['Gênero'].downcase == 'masculino' || row['Gênero'].downcase == 'male' || row['Gênero'].downcase == 'm') }) if row.include?('Gênero') && !row['Gênero'].blank?

        if user.username.nil?
          unless row['Email'].blank?
            params.merge!({ username:  row['Email'].downcase.split('@')[0][0..19] || cpf || params['Cpf'] })
          else
            params.merge!({ username: cpf })
          end
        end

        params.merge!({ birthdate: '1970-01-01' })                  if user.birthdate.nil?
        params.merge!({ nick: user.username || params[:username] }) if user.nick.nil?

        if user.new_record?
          new_password  = Devise.friendly_token.first(6)
          user.password = new_password
        end

        user.attributes = user.attributes.merge!(params.merge!({ active: true }))
      end

      if user.save
        log[:success] << I18n.t(:success, scope: [:administrations, :import_users, :log], cpf: user.cpf)
        imported << {user: user, group: group, group_name: row['Turma']}
        user.notify_user(new_password)
      else
        if user.errors[:username].blank? || (user.integrated && !can_add_to_blacklist) # if no error with username happens or cant unbind user from modulo
          log[:error] << I18n.t(:error, scope: [:administrations, :import_users, :log], cpf: user.cpf, error: user.errors.full_messages.compact.uniq.join(', '))
        else # if some error with username happens
          # set a new username
          username = user.name.slice(' ') # by name
          user.username = [username[0].downcase, username[1].downcase].join('_')[0..19] rescue user.email.split('@')[0] # by email
          user.username = user.cpf unless user.valid? # by cpf
          user.username = user.email.split('@')[0][0..19] unless user.valid? # by email
          user.username = [user.email.split('@')[0], 'tmp'].join('_')[0..19] unless user.valid? # by email

          if user.save
            log[:success] << I18n.t(:success, scope: [:administrations, :import_users, :log], cpf: user.cpf)
            imported << {user: user, group: group, group_name: row['Turma']}
            user.notify_user(new_password)

          elsif user.errors[:email].first == I18n.t('users.errors.ma.already_exists') || user.errors[:username].first == I18n.t('users.errors.ma.already_exists') # if still have errors with MA
            UserBlacklist.where(cpf: cpf).delete_all # remove from blacklist so it can be imported

            if user.save
              log[:success] << I18n.t(:success, scope: [:administrations, :import_users, :log], cpf: user.cpf)
              imported << {user: user, group: group, group_name: row['Turma']}

              blacklist = UserBlacklist.where(cpf: user.cpf).first_or_initialize # add again to blacklist
              blacklist.name = user.name
              blacklist.save

              user.notify_user(new_password)
            else
              log[:error] << I18n.t(:error, scope: [:administrations, :import_users, :log], cpf: user.cpf, error: user.errors.full_messages.compact.uniq.join(', '))
            end
          else
            log[:error] << I18n.t(:error, scope: [:administrations, :import_users, :log], cpf: user.cpf, error: user.errors.full_messages.compact.uniq.join(', '))
          end
        end
      end
    end ## each

    { imported: imported, log: log }
  end

  def notify_user(new_password)
    unless new_password.blank?
      Thread.new do
        Notifier.new_user(self, new_password).deliver
      end
    else
      notify_by_email
    end
  end

  def notify_by_email
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    self.reset_password_token = hashed_token
    self.reset_password_sent_at = Time.now.utc
    self.save(validate: false)

    Thread.new do
      Notifier.change_user(User.find(id), raw_token).deliver
    end
  end

  def self.open_spreadsheet(file, sep = ';')
    case File.extname(file.original_filename)
    when ".csv"  then Roo::CSV.new(file.path, csv_options: { col_sep: sep, encoding: Encoding::ISO_8859_1 })
    when ".xls"  then Roo::Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
    when ".ods"  then Roo::OpenOffice.new(file.path, nil, :ignore)
    else raise I18n.t('administrations.import_users.unknown_file')
    end
  end

  def notes(lesson_id, query = {})
    lesson_notes.where(lesson_id: lesson_id).where(query).order('name')
  end

  ######################
  ### integration MA ###
  ######################

  def integration
    changed_fields = (changed - CHANGEABLE_FIELDS)
    errors.add(changed_fields.first.to_sym, I18n.t('users.errors.ma.only_by')) if changed_fields.size > 0
  end

  # chamada para MA verificando se existe usuario com o login, cpf ou email informados
  def data_integration
    user_cpf = cpf.delete('.').delete('-')
    self.connect_and_validates_user
  rescue HTTPClient::ConnectTimeoutError # if MA don't respond (timeout)
    errors.add(:username, I18n.t('users.errors.ma.cant_connect')) if username_changed?
    errors.add(:cpf, I18n.t('users.errors.ma.cant_connect'))      if cpf_changed?
    errors.add(:email, I18n.t('users.errors.ma.cant_connect'))    if email_changed?
  rescue => error
    errors.add(:base, I18n.t('users.errors.ma.problem_accessing'))
  ensure
    errors_messages = errors.full_messages
    # if is new user and happened some problem connecting with MA
    if new_record? && (errors_messages.include?(I18n.t('users.errors.ma.cant_connect')) || errors_messages.include?(I18n.t('users.errors.ma.problem_accessing')))
      self.attributes = { username: user_cpf } # set username and invalid email
      user_errors     = errors.messages.to_a.collect{ |a| a[1] }.flatten.uniq # all errors
      ma_errors       = I18n.t('users.errors.ma').to_a.collect{ |a| a[1] }  # ma errors
      if (user_errors - ma_errors).empty? # form doesn't have other errors
        errors.clear # clear ma errors
      else # form has other errors
        errors.add(:username, I18n.t('users.errors.ma.login'))
        errors.add(:email, I18n.t('users.errors.ma.email'))
      end
    end
  end

  def can_synchronize?
    !on_blacklist? && (!MODULO_ACADEMICO.nil? && MODULO_ACADEMICO['integrated'])
  end

  # synchronizes user data with MA data
  def synchronize(user_data = nil)
    return nil if on_blacklist?
    return nil unless (!MODULO_ACADEMICO.nil? && MODULO_ACADEMICO['integrated'])
    user_data = User.connect_and_import_user(cpf, nil, true) if user_data.nil?

    unless user_data.blank? # if user exists
      ma_attributes = User.user_ma_attributes(user_data)
      errors.clear # clear all errors, so the system can import and save user's data

      self.synchronizing = true
      ma_attributes.merge!({encrypted_password: encrypted_password}) if ma_attributes[:encrypted_password].blank? && ma_attributes[:password].blank?

      self.attributes = attributes.merge!(ma_attributes).except('id')

      raise "username in use #{ma_attributes}, can't replace" unless username_was == ma_attributes[:username] || verify_column(self, 'username')
      unless email.blank?
        raise "email in use #{ma_attributes}, can't replace" unless email_was == ma_attributes[:email] || verify_column(self, 'email')
      end

      set_previous
      save
      self.synchronizing = false

      if errors.any?
        Rails.logger.info "\n[ERROR] [SYNCHRONIZE USER] [#{Time.now}] [USER CPF #{cpf}] message: #{errors.full_messages}"
        return false
      end

      return true
    else
      if integrated && UserBlacklist.related_with_uab(cpf)
        self.integrated = false
        save(validate: false)

      Rails.logger.info "\n[WARNING] [SYNCHRONIZE USER] [#{Time.now}] [USER CPF #{cpf}] message: not returned by si3 - setted as not integrated"
      end
      return nil
    end
  rescue => error
    Rails.logger.info "\n [ERROR] [SYNCHRONIZE USER] [#{Time.now}] [USER CPF #{cpf}] message: #{error}"
    return false
  end

  def integrated?
    can_synchronize? && integrated
  end

  def on_blacklist?
    !(UserBlacklist.find_by_cpf(self.class.cpf_without_mask(cpf)).nil?)
  end

  def add_to_blacklist(user_id = nil)
    UserBlacklist.create(cpf: cpf, name: name, user_id: user_id)
  end

  def connect_and_validates_user
    begin
      user_cpf = self.class.cpf_without_mask(cpf)

      client   = Savon.client wsdl: MODULO_ACADEMICO['wsdl']
      response = client.call MODULO_ACADEMICO['methods']['user']['validate'].to_sym, message: {cpf: user_cpf, email: email, login: username } # gets user validation

      User.validate_user_result(response.to_hash[:validar_usuario_response][:validar_usuario_result], client, user_cpf, self)
    rescue HTTPClient::ConnectTimeoutError # if MA don't respond (timeout)
      I18n.t('users.errors.ma.cant_connect')
    rescue => error
      I18n.t('users.errors.ma.problem_accessing')
    end
  end

  # user result from validation MA method
  # receives the response and the WS client
  def self.validate_user_result(result, client, cpf, user = nil)
    unless result.nil?
      cpf = cpf.delete('.').delete('-')
      cpf = cpf.rjust(11, '0')


      result = result[:int]
      cpf_user = User.find_by_cpf(cpf)
      cpf_user = User.new(cpf: cpf) if cpf_user.nil?
      if result.include?('6') && !cpf_user.on_blacklist? && (cpf_user.new_record? || cpf_user.integrated) # unavailable cpf, thus
          cpf_user.synchronize
      else
        User.ma_errors(result, user)
      end
    else
      User.ma_errors(result, user)
    end
  end

  def self.ma_errors(result, user)
    return nil if result.blank? || result == ['6']
    return nil if user.nil? # if user don't exist yet
    user.errors.add(:username, I18n.t('users.errors.ma.already_exists')) if result.include?('1')  # unavailable login/username, thus already in use by MA
    user.errors.add(:username, I18n.t('users.errors.invalid'))           if result.include?('2')  # invalid login/username
    user.errors.add(:password, I18n.t('users.errors.invalid'))           if result.include?('3')  # invalid password
    user.errors.add(:email, I18n.t('users.errors.ma.already_exists'))    if result.include?('4')  # unavailable email, thus already in use by MA
    user.errors.add(:email, I18n.t('users.errors.invalid'))              if result.include?('5')  # invalid email
    user.errors.add(:cpf, I18n.t('users.errors.invalid'))                if result.include?('7')  # invalid cpf
    user.errors.add(:base, I18n.t('users.errors.ma.problem_accessing'))  if result.include?('99') # unknown error

  end

  def self.user_ma_attributes(user_data)
    data = { name: user_data[2], cpf: user_data[0], birthdate: user_data[3], gender: (user_data[4] == 'M'), cell_phone: user_data[17], nick: (user_data[7].nil? ? ([user_data[2].split(' ')[0], user_data[2].split(' ')[1]].join(' ')) : user_data[7]), telephone: user_data[18], special_needs: ((user_data[19].blank? || user_data[19].downcase == 'nenhuma') ? nil : user_data[19]), address: user_data[10], address_number: user_data[11], zipcode: user_data[13], address_neighborhood: user_data[12], country: user_data[16], state: user_data[15], city: user_data[14], username: (user_data[5].blank? ? user_data[0] : user_data[5]), email: user_data[8], integrated: true }

    if !user_data[6].blank?
      data.merge!({password: user_data[6]})
    elsif data[:password].blank?
      # generate a random passowrd just to create user successfully
      data.merge!({password: Devise.friendly_token.first(6)})
    end

    data.merge!({selfregistration: !(user_data[6].blank? || user_data[5].blank? || user_data[8].blank?)})

    return data
  end

  def self.connect_and_import_user(cpf, client = nil, raise_error=false)
    begin
      cpf = cpf.delete('.').delete('-')
      cpf = cpf.rjust(11, '0')

      client    = Savon.client wsdl: MODULO_ACADEMICO['wsdl'] if client.nil?
      response  = client.call(MODULO_ACADEMICO['methods']['user']['import'].to_sym, message: { cpf: cpf }) # import user
      user_data = response.to_hash[:importar_usuario_response][:importar_usuario_result]
      return (user_data.nil? ? nil : user_data[:string])
    rescue HTTPClient::ConnectTimeoutError # if MA don't respond (timeout)
      if raise_error
        raise I18n.t('users.errors.ma.cant_connect')
      else
        return I18n.t('users.errors.ma.cant_connect')
      end
    rescue => error
      if raise_error
        raise I18n.t('users.errors.ma.problem_accessing')
      else
        return I18n.t('users.errors.ma.problem_accessing')
      end
    end
  end

  # alocar usuario em uma allocation_tag: profile, allocation_tags_ids, status
  def allocate_in(allocation_tag_ids: [], profile: Profile.student_profile, status: Allocation_Pending, by_user: nil)
    result = { success: [], error: [] }
    if Profile.find(profile).has_type?(Profile_Type_Admin) && status == Allocation_Activated && !by_user.try(:admin?)
      result[:error] << I18n.t(:no_permission)
      return result
    end
    Allocation.transaction do
      allocation_tag_ids.each do |at|
        al = allocations.build(allocation_tag_id: at, profile_id: profile)
        al.attributes = { status: status, updated_by_user_id: by_user }
        if al.save
          result[:success] << al

          al.calculate_working_hours rescue nil
          al.calculate_final_grade rescue nil
        else
          result[:error] << al
        end
      end
    end
    result[:success] = [] if allocation_tag_ids.size != result[:success].size
    result
  end

  def cancel_allocations(profile_id = nil, allocation_tag_id = nil, updated_by_user_id = nil)
    query = {}
    query.merge!(profile_id: profile_id)               unless profile_id.nil?
    query.merge!(allocation_tag_id: allocation_tag_id) unless allocation_tag_id.nil?

    allocations.where(query).update_all(status: Allocation_Cancelled, updated_by_user_id: updated_by_user_id)
  end

  def info(method, researcher = false)
    (researcher ? I18n.t(:hidden_info) : try(method.to_sym))
  end

  def user_photo(size = :medium)
    (photo_file_name && File.exist?(File.join(Rails.root.to_s, photo.url(size, timestamp: false)))) ? photo.url(size) : 'no_image.png'
  end

  def has_profile_type_at(allocation_tags_ids, profile_type = Profile_Type_Student)
    allocation_tags_ids = [allocation_tags_ids] unless allocation_tags_ids.class == Array
    Allocation.joins(:profile).where(status: Allocation_Activated, allocation_tag_id: allocation_tags_ids, user_id: id).where('cast(profiles.types & ? as boolean)', profile_type).any?
  end

  def verify_or_create_at_digital_class(available=nil)
    return digital_class_user_id unless digital_class_user_id.nil?
    return false unless (available.nil? ? DigitalClass.available? : available)
    # if not student neither professor, won't create user
    user = DigitalClass.call('users', { name: name, cpf: cpf, email: email, role: get_digital_class_role }, [], :post)
    self.digital_class_user_id = user['id']
    self.save(validate: false)
    return digital_class_user_id
  rescue => error
    # if error 400, ja existe la
  end

  def get_digital_class_role
    return 'professor' if profiles_with_access_on('create', 'digital_classes').any?
    return 'student'   if profiles_with_access_on('access', 'digital_classes').any?
    return nil
  end

  def update_digital_class_user(ignore_changes=false)
    DigitalClass.update_user(self, ignore_changes)
  end

  # groups that user can enroll
  def groups_to_enroll
    Offer.find_by_sql <<-SQL
      -- offers which user already is enrolled or pending at some group
      WITH offers_collection AS (
        SELECT DISTINCT g.offer_id AS id
        FROM groups g
        LEFT JOIN allocation_tags at ON at.group_id = g.id
        LEFT JOIN allocations al ON al.allocation_tag_id = at.id
        LEFT JOIN profiles p ON al.profile_id = p.id
        WHERE al.user_id = #{id}
          AND cast( p.types & '#{Profile_Type_Student}' as boolean )
      )
      SELECT o.*, COALESCE(os_e.start_date, ss_e.start_date)::date AS enroll_start_date, groups.code, groups.id AS g_id,
        CASE
          WHEN o.enrollment_schedule_id IS NULL THEN COALESCE(ss_e.end_date, ss_p.end_date)::date
          WHEN o.enrollment_schedule_id IS NOT NULL AND o.offer_schedule_id IS NULL THEN COALESCE(os_e.end_date, ss_p.end_date)::date
          ELSE COALESCE(os_e.end_date, os_p.end_date, ss_e.end_date, ss_p.end_date)::date
        END AS enroll_end_date
        FROM groups
        JOIN offers                 AS o    ON o.id = groups.offer_id
        JOIN semesters              AS s    ON s.id    = o.semester_id
        JOIN schedules              AS ss_e ON ss_e.id = s.enrollment_schedule_id -- periodo de matricula do semestre
        JOIN schedules              AS ss_p ON ss_p.id = s.offer_schedule_id -- periodo do semestre
        LEFT JOIN curriculum_units       AS uc   ON uc.id = o.curriculum_unit_id
        LEFT JOIN curriculum_unit_types  AS ct   ON ct.id = uc.curriculum_unit_type_id
        LEFT JOIN courses           AS c         ON c.id = o.course_id
   LEFT JOIN schedules              AS os_e ON os_e.id = o.enrollment_schedule_id -- periodo de matricula definido na oferta
   LEFT JOIN schedules              AS os_p ON os_p.id = o.offer_schedule_id -- periodo da oferta
       WHERE
          ((ct.id IS NULL AND c.id IS NOT NULL) OR (ct.allows_enrollment IS TRUE))
          AND (
            -- periodo de matricula informado na oferta
            (
              o.enrollment_schedule_id IS NOT NULL AND (

                -- matricula definida na oferta com data final
                (
                  os_e.end_date IS NOT NULL
                  AND
                  current_date BETWEEN os_e.start_date AND os_e.end_date -- final de matricula na oferta
                )

                -- matricula definida na oferta, mas sem data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NOT NULL
                  AND
                  current_date BETWEEN os_e.start_date AND os_p.end_date -- final de matricula no periodo da oferta
                )

                -- matricula definida na oferta sem data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NULL
                  AND
                  current_date BETWEEN os_e.start_date AND ss_p.end_date -- final de matricula no periodo do semestre
                )
              )

              OR

              -- periodo de matricula nao informado na oferta
              (
                o.enrollment_schedule_id IS NULL AND (
                  -- semestre possui matricula com data final
                  (
                    ss_e.end_date IS NOT NULL
                    AND
                    current_date BETWEEN ss_e.start_date AND ss_e.end_date -- usa periodo de matricula
                  )

                  OR

                  (
                    ss_e.end_date IS NULL
                    AND
                    current_date BETWEEN ss_e.start_date AND ss_p.end_date -- usa data final do periodo
                  )
                )
              )
            )
            AND groups.status = 't' AND o.id NOT IN (select id from offers_collection)
          ) -- where
        ORDER BY enroll_start_date DESC;
      SQL
    end


  require 'digest/md5'
  def valid_password?(password)
    integrated = integrated? && !on_blacklist?

    password = Digest::MD5.hexdigest(password) if integrated && selfregistration

    Devise.secure_compare(Digest::SHA1.hexdigest(password), self.encrypted_password)
  end

  def change_username
    self.previous_username = username
    self.username = cpf
    self.synchronizing = true
    save(validate: false)
    notify_by_email
  end

  def change_email
    unless integrated && !on_blacklist?
      self.previous_email = email
      self.email = nil
      self.synchronizing = true
      save(validate: false)
    end
  end

  def update_users_with_same_column(column)
    verify_column(self, column)
  end

  def get_email
    email || I18n.t('messages.no_mail')
  end

  def get_reset_password_token
    return (email.blank? ? set_reset_password_token : send_reset_password_instructions) unless integrated && !on_blacklist?
  end

  private

    def login_differ_from_cpf
      any_user = User.where(cpf: self.class.cpf_without_mask(username))
      errors.add(:username, I18n.t('users.errors.cpf_as_username')) if (new_record? && any_user.any?) || (any_user.where('id <> ?', id).any?)
    end

    def verify_column(user, column)
      same_column = User.where("lower(#{column}) = '#{user.send(column.to_sym).try(:downcase)}' AND users.cpf != '#{user.cpf}'")
      # ver se tem mais de um usuario com esse login
      if same_column.any?
        # se sim, é integrado e não tá na blacklist?
        if user.integrated && !user.on_blacklist? && user.selfregistration
          # altera todos os outros
          same_column.map{|u| u.send("change_#{column}".to_sym)}
        # não é integrado ou tá na blacklist?
        else
          # há algum usuário integrado com mesmo login?
          integrated = same_column.joins('LEFT JOIN user_blacklist ub ON ub.cpf = users.cpf').where(integrated: true).where('ub.id IS NULL').pluck(:id)
          integrated = User.where(id: integrated)

          send("change_#{column}".to_sym) if integrated.any?
          # muda dos outros
          (same_column - integrated).map{|u| u.send("change_#{column}".to_sym)}
          # sincroniza os integrados para atualizar dados
          integrated.map(&:synchronize)

          # verifica se ainda há usuários com mesmo username (integrados que vieram do sigaa com o mesmo login)
          remaining_users = User.where("lower(#{column}) = '#{user.send(column.to_sym).try(:downcase)}' AND cpf != '#{user.cpf}'")
          # true ou false de acordo com o resultado
          return remaining_users.empty?
        end
      else
        return true
      end
    end

    # garantees that email will be nil when blank
    def set_empty_email
      self.email = nil
    end

end
