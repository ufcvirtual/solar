class ChatRoom < Event
  include AcademicTool
  include EvaluativeTool

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :messages, class_name: 'ChatMessage', through: :academic_allocations, source: :chat_messages
  has_many :participants, class_name: 'ChatParticipant', through: :academic_allocations, source: :chat_participants
  has_many :users, through: :participants, select: ['users.name', 'users.nick', 'users.id'], uniq: true
  has_many :allocations, through: :participants

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :academic_allocations
  accepts_nested_attributes_for :participants, allow_destroy: true, reject_if: :reject_participant

  validates :title, :start_hour, :end_hour, :schedule, presence: true

  validates_format_of :start_hour, :end_hour, with: /\A([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/

  validate :verify_hours, unless: Proc.new { |a| a.start_hour.blank? || a.end_hour.blank? }

  before_validation proc { self.schedule.check_end_date = true }, if: 'schedule' # mandatory final date

  before_destroy :can_remove_groups_with_raise
  after_destroy :delete_schedule

  def reject_participant(participant)
    (participant[:allocation_id].blank? && (new_record? || participant[:id].blank?))
  end

  def user_messages
    messages.where(message_type: 1)
  end

  def can_add_group?(ats = [])
    chat_type.zero? # only add group to a chat room if current group doesn't have chat type 1
  end

  def url(allocation_id, academic_allocation_id)
    chat = YAML::load(File.open('config/chat.yml'))[Rails.env.to_s] rescue nil
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
      cipher.encrypt
      cipher.iv  = chat['IV']
      cipher.key = chat['key']
      [chat['url'].to_s, Base64.encode64(cipher.update(chat['params'].gsub('allocation_id', allocation_id.to_s).gsub('academic_id', academic_allocation_id.to_s)) + cipher.final).gsub("\n", '')].join.html_safe
  end
 

  def verify_hours
    errors.add(:end_hour, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])) if end_hour.rjust(5, '0') < start_hour.rjust(5, '0')
  end

  def delete_schedule
    self.schedule.try(:destroy)
  end

  def opened?
    start_hour, end_hour = [Date.today.to_s, self.start_hour].join(' '), [Date.today.to_s, self.end_hour].join(' ')

    # para remediar o -3h na comparacao com o horario do servidor
    now = DateTime.now
    now = DateTime.new(now.year, now.month, now.day, now.hour, now.minute)

    # precisa verificar nao so a data mas tambem a hora
    ((schedule.start_date.to_date..schedule.end_date.to_date).include?(Date.current)) && (start_hour.to_datetime <= now && end_hour.to_datetime >= now)
  end

  def started?
    DateTime.new(schedule.start_date.year, schedule.start_date.month, schedule.start_date.day, (start_hour.blank? ? 0 : start_hour.split(':').first.to_i), (start_hour.blank? ? 0 : start_hour.split(':').last.to_i)) <= DateTime.now
  end

  def self.responsible?(allocation_tag_id, user_id)
    AllocationTag.find(allocation_tag_id).is_responsible?(user_id)
  end

  def self.to_list_by_ats(allocation_tags_ids)
    joins(:schedule, :allocation_tags).where(allocation_tags: { id: allocation_tags_ids }).select('chat_rooms.*, schedules.start_date AS chat_start_date').order('chat_start_date, title').uniq
  end

  def self.chats_user(user_id, allocation_tag_id)
    allocations_with_acess =  User.find(user_id).allocation_tags_ids_with_access_on('interact','chat_rooms')

    all_chats = ChatRoom.joins(:academic_allocations, :schedule)
      .where(academic_allocations: { allocation_tag_id: allocation_tag_id })
      .select('DISTINCT chat_rooms.*, schedules.start_date, schedules.end_date, academic_allocations.id as ac_id')
      .order('schedules.start_date')

    my, others =  if responsible?(allocation_tag_id, user_id)
                    [all_chats, []]
                  else
                    without_participant = all_chats.joins('LEFT JOIN chat_participants AS cp ON cp.academic_allocation_id = academic_allocations.id').where('cp.academic_allocation_id IS NULL')
                    my = all_chats.joins(:participants, :allocations).where(allocations: { user_id: user_id })

                    if allocations_with_acess.include? allocation_tag_id
                      others = (all_chats - without_participant) - my
                      [(my + without_participant), others]
                    else
                      others = all_chats - my
                      [my, others]
                    end
                  end

    { my: my, others: others }
  end

  def self.list_chats(user_id, allocation_tag_id, evaluative=false, frequency=false)
    wq = "academic_allocations.evaluative=true" if evaluative
    wq = "academic_allocations.frequency=true" if frequency
    wq = "academic_allocations.evaluative=false AND academic_allocations.frequency=false" if !evaluative && !frequency

    allocations_with_acess =  User.find(user_id).allocation_tags_ids_with_access_on('interact','chat_rooms')
    all_chats = ChatRoom.joins(:academic_allocations, :schedule)
      .where(academic_allocations: {allocation_tag_id: allocation_tag_id}) 
      .where(wq)
      .select("DISTINCT chat_rooms.*, schedules.start_date, schedules.end_date, academic_allocations.id as ac_id, CASE 
        WHEN schedules.start_date > current_date THEN 'message_did_not_start' WHEN schedules.end_date < current_date THEN 'message_ended' END AS situation")
      .order('schedules.start_date')

    my, others =  if responsible?(allocation_tag_id, user_id)
                    [all_chats, []]
                  else
                    without_participant = all_chats.joins('LEFT JOIN chat_participants AS cp ON cp.academic_allocation_id = academic_allocations.id').where('cp.academic_allocation_id IS NULL')
                    my = all_chats.joins(:participants, :allocations).where(allocations: { user_id: user_id })

                    if allocations_with_acess.include? allocation_tag_id
                      others = (all_chats - without_participant) - my
                      [(my + without_participant), others]
                    else
                      others = all_chats - my
                      [my, others]
                    end
                  end
    { my: my, others: others }
  end

  def get_messages(at_id, user_query={})
    user_query = ['users.id = :user_id OR allocations.user_id = :user_id AND message_type = 1', user_query] unless user_query[:user_id].nil?
    ChatMessage.joins(:academic_allocation, allocation: [:user, :profile])
               .joins('LEFT JOIN academic_allocation_users acu ON acu.academic_allocation_id = chat_messages.academic_allocation_id AND (acu.user_id = chat_messages.user_id OR acu.user_id = allocations.user_id)')
               .joins("LEFT JOIN allocations students ON allocations.id = students.id AND cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
               .where(academic_allocations: {allocation_tag_id: at_id, academic_tool_id: id, academic_tool_type: 'ChatRoom'})
               .where(user_query)
               .select("COALESCE(users.id, allocations.user_id) AS u_id, users.name AS user_name, users.nick AS user_nick, profiles.name AS profile_name, text, chat_messages.user_id, chat_messages.created_at, acu.grade AS grade, acu.working_hours AS wh, 
                 CASE 
                 WHEN students.id IS NULL THEN false
                 ELSE true
                 END AS is_student,
                 message_type")
               .order('created_at DESC')
  end

  def self.update_previous(academic_allocation_id, user_id, academic_allocation_user_id)
    ChatMessage.where(academic_allocation_id: academic_allocation_id, user_id: user_id).update_all academic_allocation_user_id: academic_allocation_user_id
  end  

  def self.verify_previous(acu_id)
    ChatMessage.where(academic_allocation_user_id: acu_id).any?
  end

end
