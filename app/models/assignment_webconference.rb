class AssignmentWebconference < ActiveRecord::Base

  attr_accessor :api_call

  include Bbb
  include ControlledDependency
  include SentActivity

  belongs_to :academic_allocation_user

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  has_one :assignment, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation

  before_save :can_change?, if: 'merge.nil?'

  before_destroy :can_destroy?, :remove_records, if: 'merge.nil?'

  validates :title, :initial_time, :duration, :academic_allocation_user_id, presence: true
  validates :duration, numericality: { only_integer: true, less_than_or_equal_to: 60,  greater_than_or_equal_to: 1 }
  validates :title, length: { maximum: 255 }

  validate :cant_change_date, on: :update, if: '(!duration.nil? && !initial_time.nil?) && (initial_time_changed? || duration_changed?)'

  validate :verify_quantity_users, :verify_time, if: '(((initial_time_changed? || duration_changed?)) || new_record?) && merge.nil? && (!duration.nil? && !initial_time.nil?)'

  validate :verify_assignment_time, if: '(!duration.nil? && !initial_time.nil?) && (duration_changed? || initial_time_changed? || new_record?) && merge.nil?'

  validates :academic_allocation_user_id, presence: true

  def can_change?
    raise CanCan::AccessDenied unless api_call? || is_owner?
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
    meeting_id   = get_mettingID
    meeting_name = [title, aw_info].join(' - ').truncate(100)

    options = {
      moderatorPW: Digest::MD5.hexdigest(title+meeting_id),
      attendeePW: Digest::MD5.hexdigest(meeting_id),
      welcome: academic_allocation_user.assignment.enunciation,
      record: true,
      autoStartRecording: is_recorded,
      allowStartStopRecording: true,
      logoutURL: YAML::load(File.open('config/webconference.yml'))['feedback_url'] || Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: academic_allocation_user.users_count + 1 # students + 1 responsible
    }

    @api = bbb_prepare

    @api.create_meeting(meeting_name, meeting_id, options) unless @api.is_meeting_running?(meeting_id)

    group_id = academic_allocation_user.group_assignment_id

    if group_id.nil? || GroupParticipant.where(group_assignment_id: group_id, user_id: user.id).any?
      @api.join_meeting_url(meeting_id, "#{user.name}*", options[:moderatorPW])
    elsif AllocationTag.find(academic_allocation.allocation_tag_id).is_responsible?(user.id)
      @api.join_meeting_url(meeting_id, user.name, options[:attendeePW])
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
    response   = api.get_recordings()
    response[:recordings].each do |m|
      api.delete_recordings(m[:recordID]) if m[:meetingID] == meeting_id
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

  def api_call?(value = false)
    @api_call = @api_call ? @api_call : value
  end

end
