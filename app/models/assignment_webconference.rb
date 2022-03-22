class AssignmentWebconference < ActiveRecord::Base

  include Bbb
  include ControlledDependency
  include SentActivity

  belongs_to :academic_allocation_user

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  has_one :assignment, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation

  before_save :can_change?, if: -> {merge.nil?}

  before_destroy :can_destroy?, :remove_records, if: -> {merge.nil?}

  validates :title, :initial_time, :duration, :academic_allocation_user_id, presence: true
  validates :duration, numericality: { only_integer: true, less_than_or_equal_to: 60,  greater_than_or_equal_to: 1 }
  validates :title, length: { maximum: 255 }

  validate :cant_change_date, on: :update, if: -> {(!duration.nil? && !initial_time.nil?) && (saved_change_to_initial_time? || saved_change_to_duration?)}

  validate :verify_quantity_users, :verify_time, if: -> {(((saved_change_to_initial_time? || saved_change_to_duration?)) || new_record?) && merge.nil? && (!duration.nil? && !initial_time.nil?)}

  validate :verify_assignment_time, if: -> {(!duration.nil? && !initial_time.nil?) && (saved_change_to_duration? || saved_change_to_initial_time? || new_record?) && merge.nil?}

  validates :academic_allocation_user_id, presence: true

  def can_change?
    raise CanCan::AccessDenied unless is_owner?
    raise 'date_range'         unless assignment.in_time?
  end

  def order
   'updated_at DESC'
  end

  def delete_with_dependents
    self.delete
  end

  def is_owner?
    owner(User.current.try(:id))
  end

  def in_time?
    assignment.in_time?
  end

  def bbb_join(user)

    web = AssignmentWebconference.find(id)
    domain = Bbb.get_domain_server(web.server)
    meeting_id   = get_mettingID
    meeting_name = [title, aw_info].join(' - ').truncate(100)
    #aa_user_id = web.academic_allocation_user_id.to_s
    moderator_email = web.academic_allocation_user.user.email rescue web.academic_allocation_user.group_assignment.users.map(&:email).compact.join(',')
    downloadable = false

    options = {
      moderatorPW: Digest::MD5.hexdigest(title+meeting_id),
      # moderatorPW: Digest::MD5.hexdigest(aa_user_id+meeting_id),
      attendeePW: Digest::MD5.hexdigest(meeting_id),
      welcome: academic_allocation_user.assignment.enunciation,
      record: true,
      autoStartRecording: is_recorded,
      allowStartStopRecording: true,
      logoutURL: YAML::load(File.open('config/webconference.yml'))['feedback_url'] || Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: academic_allocation_user.users_count + 3, # students + 3 responsible
      "meta_bbb-origin": "Solar(assignment)",
      "meta_bbb-origin-server-name": domain,
      "meta_email": moderator_email,
      "meta_download": downloadable
    }

    @api = bbb_prepare

    @api.create_meeting(meeting_name, meeting_id, options) unless @api.is_meeting_running?(meeting_id)

    group_id = academic_allocation_user.group_assignment_id
    user_name = (user.use_nick_at_webconference ? user.nick : user.name)

    if group_id.nil? || GroupParticipant.where(group_assignment_id: group_id, user_id: user.id).any?
      @api.join_meeting_url(meeting_id, "#{user_name}*", options[:moderatorPW])
    elsif AllocationTag.find(academic_allocation.allocation_tag_id).is_responsible?(user.id)
      @api.join_meeting_url(meeting_id, user_name, options[:attendeePW])
    end
  end

  def get_mettingID(at_id = nil)
    (origin_meeting_id || ['aw', id.to_s].join('_')).to_s
  end

  def get_bbb_url(user)
    ((on_going? && bbb_online? && owner_or_responsible(user.id)) ? bbb_join(user) : nil)
  end

  def owner(user_id)
    Assignment.owned_by_user?(user_id, { academic_allocation_user: academic_allocation_user })
  end

  def owner_or_responsible(user_id)
    owner(user_id) || AllocationTag.find(academic_allocation.allocation_tag_id).is_responsible?(user_id)
  end

  def aw_info
    [(academic_allocation_user.group_assignment_id.nil? ? academic_allocation_user.user.name.truncate(15) : academic_allocation_user.group_assignment.group_name), academic_allocation_user.academic_allocation.allocation_tag.info].join(' - ')
  end

  def remove_records
    api        = bbb_prepare
    meeting_id = get_mettingID
    # response   = api.get_recordings()
    options = {meetingID: meeting_id}
    response   = api.get_recordings(options)
    response[:recordings].each do |m|
      api.delete_recordings(m[:recordID])# if m[:meetingID] == meeting_id
    end
  end

  def set_origin(from_id)
    obj = self.class.find(from_id)
    self.origin_meeting_id = (obj.origin_meeting_id || obj.get_mettingID) if (on_going? || over?)
  end

  def verify_assignment_time
    has_hours = (!assignment.start_hour.blank? && !assignment.end_hour.blank?)
    startt    = (has_hours ? (assignment.schedule.start_date.beginning_of_day + assignment.start_hour.split(':')[0].to_i.hours + assignment.start_hour.split(':')[1].to_i.minutes) : assignment.schedule.start_date.beginning_of_day)
    endt      = (has_hours ? (assignment.schedule.end_date.beginning_of_day + assignment.end_hour.split(':')[0].to_i.hours + assignment.end_hour.split(':')[1].to_i.minutes) : assignment.schedule.end_date.end_of_day)
    time_webconference = initial_time + duration * 60

    errors.add(:initial_time, I18n.t('assignments.error.not_range_webconference')) unless (initial_time.between?(startt,endt) && time_webconference.between?(startt,endt))
    errors.add(:initial_time,  I18n.t('assignments.error.invalid_datetime')) if !(initial_time.blank?) && (initial_time < Date.current)
  end

end
