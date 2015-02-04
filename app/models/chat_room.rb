class ChatRoom < Event
  include AcademicTool

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :messages, class_name: "ChatMessage", through: :academic_allocations, source: :chat_messages
  has_many :participants, class_name: "ChatParticipant", through: :academic_allocations, source: :chat_participants
  has_many :users, through: :participants, select: ["users.name", "users.nick"], uniq: true
  has_many :allocations, through: :participants

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :academic_allocations

  validates :title, :start_hour, :end_hour, :schedule, presence: true

  validates_format_of :start_hour, :end_hour, with: /\A([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? or a.end_hour.blank? }

  before_destroy :can_destroy?
  after_destroy :delete_schedule

  def user_messages
    messages.where(message_type: 1)
  end

  def can_add_group?
    chat_type.zero? # only add group to a chat room if current group doesn't have chat type 1
  end

  def url(allocation_id, academic_allocation_id)
    chat = YAML::load(File.open('config/chat.yml'))[Rails.env.to_s] rescue nil
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
    cipher.encrypt
    cipher.iv  = chat['IV']
    cipher.key = chat['key']

    [chat["url"], Base64.encode64(cipher.update(chat["params"].gsub("allocation_id", allocation_id.to_s).gsub("academic_id", academic_allocation_id.to_s)) + cipher.final).gsub("\n",'')].join.html_safe
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

  def can_remove_groups?(groups)
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
    AllocationTag.find(allocation_tag_id).is_responsible?(user_id)
  end


  ## class methods

  def self.to_list_by_ats(allocation_tags_ids)
    joins(:schedule, :allocation_tags).where(allocation_tags: {id: allocation_tags_ids}).select("chat_rooms.*, schedules.start_date AS chat_start_date").order("chat_start_date, title").uniq
  end

  def self.chats_user(user_id, allocation_tag_id)
    allocations_with_acess =  User.find(user_id).allocation_tags_ids_with_access_on('interact','chat_rooms')

    all_chats = ChatRoom.joins(:academic_allocations, :schedule)
      .where(academic_allocations: {allocation_tag_id: allocation_tag_id})
      .select('DISTINCT chat_rooms.*, schedules.start_date, schedules.end_date')
      .order('schedules.start_date')

    my, others = if responsible?(allocation_tag_id, user_id)
      [all_chats, []]
    else
      without_participant = all_chats.joins('LEFT JOIN chat_participants AS cp ON cp.academic_allocation_id = academic_allocations.id').where('cp.academic_allocation_id IS NULL')
      my = all_chats.joins(:participants, :allocations).where(allocations: {user_id: user_id})

      if allocations_with_acess.include? allocation_tag_id
        others = (all_chats - without_participant) - my
        [(my + without_participant), others]
      else
        others = all_chats - my
        [my, others]
      end

    end

    {my: my, others: others}
  end

end
