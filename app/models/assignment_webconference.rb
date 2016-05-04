class AssignmentWebconference < ActiveRecord::Base
  include Bbb

  belongs_to :sent_assignment

  has_one :academic_allocation, through: :sent_assignment, autosave: false

  before_save :can_change?, if: 'merge.nil?'

  before_destroy :can_destroy?, :remove_record

  validates :title, :initial_time, :duration, :sent_assignment_id, presence: true
  validates :duration, numericality: { only_integer: true, less_than_or_equal_to: 60,  greater_than_or_equal_to: 1 }
  validates :title, length: { maximum: 255 }

  validate :cant_change_date, only: :update, if: 'initial_time_changed? || duration_changed?'

  validate :verify_quantity_users, :verify_time, if: '((!(duration.nil? || initial_time.nil?) && (initial_time_changed? || duration_changed?)) || new_record?) && merge.nil?'

  default_scope order: 'updated_at DESC'

  attr_accessor :merge

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

  def allocation_tag
    academic_allocation.allocation_tag
  end

  def can_change?
    raise CanCan::AccessDenied unless is_owner?
    raise 'date_range'         unless assignment.in_time?
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
      welcome: sent_assignment.assignment.enunciation,
      record: is_recorded,
      logoutURL: Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: sent_assignment.users_count + 1 # students + 1 responsible
    }

    @api = bbb_prepare

    @api.create_meeting(meeting_name, meeting_id, options) unless @api.is_meeting_running?(meeting_id)

    group_id = sent_assignment.group_assignment_id

    if group_id.nil? || GroupParticipant.where(group_assignment_id: group_id, user_id: user.id).any?
      @api.join_meeting_url(meeting_id, "#{user.name}*", options[:moderatorPW])
    elsif responsible?(user.id)
      @api.join_meeting_url(meeting_id, user.name, options[:attendeePW])
    end
  end

  def get_mettingID(at_id = nil)
    (origin_meeting_id || ['aw', id.to_s].join('_'))
  end

  def get_bbb_url(user)
    ((on_going? && bbb_online? && owner_or_responsible(user.id)) ? ActionController::Base.helpers.link_to(title, bbb_join(user), target: '_blank') : title)
  end

  def owner(user_id)
    Assignment.owned_by_user?(user_id, { sent_assignment: sent_assignment })
  end

  def owner_or_responsible(user_id)
    owner(user_id) || AllocationTag.find(academic_allocation.allocation_tag_id).is_responsible?(user_id)
  end

  def aw_info
    [(sent_assignment.has_group ? sent_assignment.group_assignment.group_name : sent_assignment.user.name.truncate(15)), sent_assignment.academic_allocation.allocation_tag.info].join(' - ')
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
    self.origin_meeting_id = (obj.origin_meeting_id || obj.get_mettingID) if is_recorded? && (on_going? || over?)
  end

end
