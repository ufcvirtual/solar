class ChatRoom < Event

  GROUP_PERMISSION = true

  has_many :messages, class_name: "ChatMessage"
  has_many :participants, class_name: "ChatParticipant", dependent: :destroy
  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  has_many :users, through: :participants, select: [:name, :nick], order: :name
  has_many :allocations, through: :participants

  belongs_to :schedule

  accepts_nested_attributes_for :schedule

  validates :title, :start_hour, :end_hour, presence: true

  validates_format_of :start_hour, :end_hour, with: /\A([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank?}

  accepts_nested_attributes_for :participants, allow_destroy: true, reject_if: proc { |attributes| attributes['allocation_id'] == "0" }

  attr_accessible :participants_attributes, :title, :start_hour, :end_hour, :description, :schedule_attributes, :chat_type, :schedule_id

  before_destroy :can_destroy?
  after_destroy :delete_schedule

  def url(allocation_id)
    chat = YAML::load(File.open('config/chat.yml'))[Rails.env.to_s] rescue nil
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
    cipher.encrypt
    cipher.iv  = chat['IV']
    cipher.key = chat['key']

    [chat["url"], Base64.encode64(cipher.update(chat["params"].gsub("allocation_id", allocation_id.to_s).gsub("id", id.to_s)) + cipher.final).gsub("\n",'')].join
  end

  def verify_hours
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if end_hour.rjust(5, '0') < start_hour.rjust(5, '0')
  end

  def delete_schedule
    self.schedule.destroy
  end

  def can_destroy?
    self.messages.empty?
  end

  def copy_dependencies_from(chat_to_copy)
    ChatParticipant.create! chat_to_copy.participants.map {|participant| participant.attributes.merge({chat_room_id: self.id})} unless chat_to_copy.participants.empty?
  end

  def can_remove_or_unbind_group?(group)
    self.messages.empty? # não pode dar unbind nem remover se chat possuir mensagens
  end

  def opened?
    start_hour, end_hour = [Date.today.to_s, self.start_hour].join(" "), [Date.today.to_s, self.end_hour].join(" ")
 
     # para remediar o -3h na comparação com o horário do servidor
     now = DateTime.now
     now = DateTime.new(now.year, now.month, now.day, now.hour, now.minute)
 
    # precisa verificar não só a data mas também a hora
    ((schedule.start_date.to_date..schedule.end_date.to_date).include?(Date.current)) and (start_hour.to_datetime <= now and end_hour.to_datetime >= now)
  end

  def self.responsible?(allocation_tag_id, user_id)
    AllocationTag.find(allocation_tag_id).is_user_class_responsible?(user_id)
  end

  def self.chats_user(allocation_tag_id, user_id)
    if responsible?(allocation_tag_id, user_id)
      raise "qui"
      # responsavel: devolve todas as salas de chat
      ChatRoom.joins(:academic_allocations, :allocation_tags, :schedule)
        .select("chat_rooms.*, schedules.start_date, schedules.end_date")
        .where(allocation_tags: {id: allocation_tag_id})
        .order("schedules.start_date").uniq
    else
      my = ChatRoom.joins(:academic_allocations, :allocation_tags, :participants, :users, :schedule)
        .select("chat_rooms.*, schedules.start_date, schedules.end_date")
        .where(allocation_tags: {id: allocation_tag_id}, users: {id: user_id})
        .order("schedules.start_date").uniq

      open = ChatRoom.joins(:academic_allocations, :allocation_tags, :schedule)
        .select("chat_rooms.*, schedules.start_date, schedules.end_date")
        .where(allocation_tags: {id: allocation_tag_id}, chat_type: 0)
        .order("schedules.start_date").uniq
      
      my + open # devolve as salas de chat em que o usuário está mais as salas abertas que não definem participantes
    end
  end

  def self.chats_other_users(allocation_tag_id, user_id)
    all = ChatRoom.joins(:academic_allocations, :allocation_tags, :schedule)
      .select("chat_rooms.*, schedules.start_date, schedules.end_date")
      .where(allocation_tags: {id: allocation_tag_id})
      .order("schedules.start_date").uniq

    all - chats_user(allocation_tag_id, user_id) # devolve as salas de chat em que o usuario nao esta
  end

end
