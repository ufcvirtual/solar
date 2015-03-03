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

  after_destroy :remove_record, if: Proc.new { |a| a.is_recorded }

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
    Time.now > (initial_time+duration.minutes+10.minutes)
  end

  def link_to_join(user, at)
    ((can_access? && is_online?) ? ActionController::Base.helpers.link_to(title, bbb_join(user, at), target: "_blank") : title)
  end

  def is_meeting_running(meeting_id)
    @api.is_meeting_running?(meeting_id)
  end

  def status
    case
    when !is_online? then I18n.t(:unavailable, scope: [:webconferences, :list])
    when can_access? then I18n.t(:in_progress, scope: [:webconferences, :list])
    when (Time.now < initial_time) then I18n.t(:scheduled, scope: [:webconferences, :list])
    when (is_recorded? && is_online?)
      if is_over?
        ActionController::Base.helpers.link_to(I18n.t(:play, scope: [:webconferences, :list]), recordings, target: "_blank")
      else
        I18n.t(:processing, scope: [:webconferences, :list])
      end
    else
     I18n.t(:finish, scope: [:webconferences, :list])
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids, opt = { order: 'initial_time ASC, title ASC' })
    # AcademicAllocation.where(allocation_tag_id: allocation_tags_ids)
    Webconference.joins("JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Webconference'").select('webconferences.*, academic_allocations.allocation_tag_id AS at_id').order(opt[:order])
    # AcademicAllocation.joins("JOIN webconferences ON webconferences.id = academic_allocations.academic_tool_id").where(academic_tool_type: 'Webconference').select('academic_allocations.id AS ac_id, webconferences.*').order(opt[:order])
    # (allocation_tags_ids.include?(nil) ? select("webconferences.*, DISTINCT academic_allocations.id AS academic_allocation_id").order(opt[:order]) : joins(academic_allocations: :allocation_tag).where(allocation_tags: { id: allocation_tags_ids }).select("webconferences.*, DISTINCT academic_allocations.id AS academic_allocation_id").order(opt[:order]))
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

  def bbb_join(user, at)
    meeting_name   = AllocationTag.find(at).info
    meeting_id     = "#{meeting_name}-#{id}"
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

  def recordings
    meeting_id = get_mettingID
    @api = Webconference.bbb_prepare

    response = @api.get_recordings
    response[:recordings].each do |m|
      if m[:meetingID] == meeting_id
        playback = m[:playback]
        format = playback[:format]
        url = format[:url]
        return url
      end
    end
    return '#'
  end

  def get_mettingID
    meeting_name =  unless groups.empty?
                      groups.map(&:code).join(', ')
                    else
                      o = offers.first
                      "#{o.curriculum_unit.name}-#{o.semester.name}"
                    end
    meeting_id = "#{meeting_name}-#{id}"
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

  def self.remove_record(webconferences, at)
    api = Webconference.bbb_prepare

    webconferences.each do |webconference|
      meeting_name =  unless webconference.groups.empty?
                        webconference.groups.map(&:code).join(', ')
                      else
                        o = webconference.offers.first
                        "#{(o.curriculum_unit.name || o.course.name)}-#{o.semester.name}"
                      end

      meeting_id = "#{meeting_name}-#{webconference.id}"

      response = @api.get_recordings()
      response[:recordings].each do |m|
        api.delete_recordings(m[:recordID]) if m[:meetingID] == meeting_id
      end
      webconference.update_attributes(is_recorded: false)
    end
  end

  def remove_record
    Webconference.remove_record([self])
  end
end
