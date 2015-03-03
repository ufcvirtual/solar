require 'bigbluebutton_api'

class Webconference < ActiveRecord::Base

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :moderator, class_name: 'User', foreign_key: :user_id

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  validates :title, :initial_time, :duration, presence: true
  validates :title, :description, length: { maximum: 255 }

  before_destroy :can_destroy?

  def can_access?
    Time.now.between?(initial_time, initial_time+duration.minutes)
  end

  def is_online?
    begin
      @api = Webconference.bbb_prepare
      url  = URI(@api.url)
      response = Net::HTTP.get_response(url)
      return (Net::HTTPSuccess === response)
    rescue Errno::ECONNREFUSED
      false
    end
  end

  def is_over?
    Time.now > (initial_time+duration.minutes+1.minutes)
  end

  def link_to_join(user, at_id)
    ((can_access? && is_online?) ? ActionController::Base.helpers.link_to(title, bbb_join(user, at_id), target: "_blank") : title)
  end

  def is_meeting_running(meeting_id)
    @api.is_meeting_running?(meeting_id)
  end

  def status(at_id)
    case
    when !is_online? then I18n.t(:unavailable, scope: [:webconferences, :list])
    when can_access? then I18n.t(:in_progress, scope: [:webconferences, :list])
    when (Time.now < initial_time) then I18n.t(:scheduled, scope: [:webconferences, :list])
    when (is_recorded? && is_online?)
      if is_over?
        record_url = recordings(at_id)
        (record_url ? ActionController::Base.helpers.link_to(I18n.t(:play, scope: [:webconferences, :list]), record_url, target: "_blank") : I18n.t(:removed_record, scope: [:webconferences, :list]))
      else
        I18n.t(:processing, scope: [:webconferences, :list])
      end
    else
     I18n.t(:finish, scope: [:webconferences, :list])
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids, opt = { order: 'initial_time ASC, title ASC' })
    webconferences = Webconference.joins("JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Webconference'")
    webconferences = webconferences.where(academic_allocations: { allocation_tag_id: allocation_tags_ids }) unless allocation_tags_ids.include?(nil)
    webconferences.select('webconferences.*, academic_allocations.allocation_tag_id AS at_id, academic_allocations.id AS ac_id').order(opt[:order])
  end

  def responsible?(user_id)
    !(allocation_tags.map{ |at| at.is_responsible?(user_id) }.include?(false))
  end

  def self.bbb_prepare
    @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
    server  = @config['servers'][@config['servers'].keys.first]
    debug   = @config['debug']
    BigBlueButton::BigBlueButtonApi.new(server['url'], server['salt'], server['version'].to_s, debug)
  end

  def bbb_join(user, at_id)
    meeting_name   = AllocationTag.find(at_id).info
    meeting_id     = get_mettingID(at_id)
    meeting_name   = "#{title} (#{meeting_name})"
    moderator_name = "#{user.name}*"
    attendee_name  = user.name

    options = {
      moderatorPW: Digest::MD5.hexdigest("#{meeting_id}"),
      attendeePW: Digest::MD5.hexdigest(id.to_s),
      welcome: description,
      duration: duration,
      record: is_recorded,
      logoutURL: Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: 35
    }

    @api = Webconference.bbb_prepare
    @api.create_meeting(meeting_name, meeting_id, options) unless @api.is_meeting_running?(meeting_id)

    if (responsible?(user.id) || user.can?(:manage, Webconference, { on: academic_allocations.flatten.map(&:allocation_tag_id).flatten, accepts_general_profile: true }))
      @api.join_meeting_url(meeting_id, moderator_name, options[:moderatorPW])
    else
      @api.join_meeting_url(meeting_id, attendee_name, options[:attendeePW])
    end
  end

  def recordings(at_id)
    meeting_id = get_mettingID(at_id)
    @api = Webconference.bbb_prepare

    response = @api.get_recordings()
    response[:recordings].each do |m|
      if m[:meetingID] == meeting_id
        playback = m[:playback]
        format = playback[:format]
        url = format[:url]
        return url
      end
    end
    return false
  end

  def get_mettingID(at_id)
    [at_id.to_s, id.to_s].join('_')
  end

  def can_remove_records?
    raise 'not_recorded' unless is_recorded?
    raise 'unavailable'  unless is_online?
    raise 'not_ended'    unless is_over?
  end

  def can_destroy?
    raise 'unavailable'  if is_recorded? && !is_online?
    raise 'not_ended'    unless is_over?
  end

  def self.remove_record(academic_allocations)
    api = Webconference.bbb_prepare

    academic_allocations.each do |academic_allocation|
      webconference = Webconference.find(academic_allocation.academic_tool_id)
      meeting_id    = webconference.get_mettingID(academic_allocation.allocation_tag_id)
      response      = api.get_recordings()
      response[:recordings].each do |m|
        api.delete_recordings(m[:recordID]) if m[:meetingID] == meeting_id
      end
    end
  end

  def can_unbind?
    !(is_over? && is_recorded)
  end
end
