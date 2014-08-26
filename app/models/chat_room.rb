class ChatRoom < Event

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :messages, class_name: "ChatMessage", through: :academic_allocations, source: :chat_messages
  has_many :participants, class_name: "ChatParticipant", through: :academic_allocations#, source: :chat_participants
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :users, through: :participants, select: [:name, :nick], order: :name, uniq: true
  has_many :allocations, through: :participants

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :academic_allocations

  validates :title, :start_hour, :end_hour, presence: true

  validates_format_of :start_hour, :end_hour, with: /\A([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank?}

  attr_accessible :schedule_attributes, :academic_allocations_attributes, :title, :start_hour, :end_hour, :description, :chat_type, :schedule_id

  before_destroy :can_destroy?
  after_destroy :delete_schedule

  def user_messages
    messages.where(message_type: 1)
  end

  def url(allocation_id, academic_allocation_id)
    chat = YAML::load(File.open('config/chat.yml'))[Rails.env.to_s] rescue nil
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
    cipher.encrypt
    cipher.iv  = chat['IV']
    cipher.key = chat['key']

    [chat["url"], Base64.encode64(cipher.update(chat["params"].gsub("allocation_id", allocation_id.to_s).gsub("academic_id", academic_allocation_id.to_s)) + cipher.final).gsub("\n",'')].join
  end

  def verify_hours
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if end_hour.rjust(5, '0') < start_hour.rjust(5, '0')
  end

  def delete_schedule
    self.schedule.try(:destroy)
  end

  def can_destroy?
    if user_messages.any?
      errors.add(:base, I18n.t(:chat_has_messages, scope: [:chat_rooms, :error]))
      return false
    end
    return true
  end

  # def copy_dependencies_from(chat_to_copy)
  #   ChatParticipant.create! chat_to_copy.participants.map {|participant| participant.attributes.merge({chat_room_id: self.id})} unless chat_to_copy.participants.empty?
  # end

  def can_remove_or_unbind_group?(group)
    user_messages.empty? # não pode dar unbind nem remover se chat possuir mensagens
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
    AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(user_id)
  end

  def self.chats_user(user_id, allocation_tag_id)
    all_chats = ChatRoom.joins(:academic_allocations, :schedule) \
      .select('DISTINCT chat_rooms.*, schedules.start_date, schedules.end_date') \
      .where(academic_allocations: {allocation_tag_id: allocation_tag_id}) \
      .order('schedules.start_date')

    my, others = if responsible?(allocation_tag_id, user_id)
      [all_chats, []]
    else
      without_user = all_chats.joins('LEFT JOIN chat_participants AS cp ON cp.academic_allocation_id = academic_allocations.id').where('cp.academic_allocation_id IS NULL')
      my = all_chats.joins(:participants, :allocations).where(allocations: {user_id: user_id})
      others = (all_chats - without_user) - my

      [(my + without_user), others]
    end

    {my: my, others: others}
  end

end
