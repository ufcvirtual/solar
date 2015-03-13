require 'bigbluebutton_api'

class Webconference < ActiveRecord::Base

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :moderator, class_name: 'User', foreign_key: :user_id

  before_destroy :can_destroy?, :remove_records

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  validates :title, :initial_time, :duration, presence: true
  validates :title, :description, length: { maximum: 255 }

  def can_access?
    Time.now.between?(initial_time, initial_time+duration.minutes)
  end

  def self.online?
    begin
      api = Webconference.bbb_prepare
      url  = URI(api.url)
      response = Net::HTTP.get_response(url)
      return (Net::HTTPSuccess === response)
    rescue Errno::ECONNREFUSED
      false
    end
  end

  def is_over?
    Time.now > (initial_time+duration.minutes+1.minutes)
  end

  def link_to_join(user, at_id = nil)
    ((can_access? && Webconference.online? && have_permission?(user, at_id)) ? ActionController::Base.helpers.link_to(title, bbb_join(user, at_id), target: '_blank') : title) 
  end

  def status(recordings = [], at_id = nil)
    case
    when can_access? then I18n.t(:in_progress, scope: [:webconferences, :list])
    when (Time.now < initial_time) then I18n.t(:scheduled, scope: [:webconferences, :list])
    when is_recorded?
      if is_over?
        record_url = recordings(recordings, at_id)
        (record_url ? ActionController::Base.helpers.link_to(I18n.t(:play, scope: [:webconferences, :list]), record_url, target: '_blank') : I18n.t(:removed_record, scope: [:webconferences, :list]))
      else
        I18n.t(:processing, scope: [:webconferences, :list])
      end
    else
     I18n.t(:finish, scope: [:webconferences, :list])
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids, opt = { asc: true })
    query  = allocation_tags_ids.include?(nil) ? {} : { academic_allocations: { allocation_tag_id: allocation_tags_ids } }
    opt.merge!(select2: 'webconferences.*, academic_allocations.allocation_tag_id AS at_id, academic_allocations.id AS ac_id, users.name AS user_name')
    opt.merge!(select1: 'DISTINCT webconferences.id, webconferences.*, NULL AS at_id, NULL AS ac_id, users.name AS user_name')

    webconferences = Webconference.joins(:moderator).joins("JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Webconference'").where(query)
    web1 = webconferences.where(shared_between_groups: true)
    web2 = webconferences.where(shared_between_groups: false)

    (web1.select(opt[:select1]) + web2.select(opt[:select2])).sort_by{ |web| (opt[:asc] ? [web.initial_time.to_i, web.title] : [-web.initial_time.to_i, web.title]) }
  end

  def responsible?(user_id, at_id = nil)
    ((shared_between_groups || at_id.nil?) ? (allocation_tags.map{ |at| at.is_responsible?(user_id) }.include?(true)) : AllocationTag.find(at_id).is_responsible?(user_id))
  end

   def student_or_responsible?(user_id, at_id = nil)
    ((shared_between_groups || at_id.nil?) ? (allocation_tags.map{ |at| at.is_student_or_responsible?(user_id) }.include?(true)) : AllocationTag.find(at_id).is_student_or_responsible?(user_id))
  end

  def self.bbb_prepare
    @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
    server  = @config['servers'][@config['servers'].keys.first]
    debug   = @config['debug']
    BigBlueButton::BigBlueButtonApi.new(server['url'], server['salt'], server['version'].to_s, debug)
  end

  def location
    groups_codes = groups.map(&:code).join(', ') unless groups.empty?
    offer        = groups.first.try(:offer) || offers.first
    [offer.allocation_tag.info, groups_codes].join(' - ')
  end

  def groups_codes
    groups.map(&:code) unless groups.empty?
  end

  def offer_info
    (groups.first.try(:offer) || offers.first).allocation_tag.info
  end

  def bbb_join(user, at_id = nil)
    meeting_id   = get_mettingID(at_id)
    meeting_name = [title, offer_info].join(' - ').truncate(100)

    options = {
      moderatorPW: Digest::MD5.hexdigest(title+meeting_id),
      attendeePW: Digest::MD5.hexdigest(meeting_id),
      welcome: description,
      duration: duration,
      record: is_recorded,
      logoutURL: Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: 35
    }

    @api = Webconference.bbb_prepare
    @api.create_meeting(meeting_name, meeting_id, options) unless @api.is_meeting_running?(meeting_id)

    if (responsible?(user.id) || user.can?(:preview, Webconference, { on: academic_allocations.flatten.map(&:allocation_tag_id).flatten, accepts_general_profile: true, any: true }))
      @api.join_meeting_url(meeting_id, "#{user.name}*", options[:moderatorPW])
    else
      @api.join_meeting_url(meeting_id, user.name, options[:attendeePW])
    end
  end

  def have_permission?(user, at_id = nil)
    (student_or_responsible?(user.id, at_id) || 
      (
        ats = (shared_between_groups || at_id.nil?) ? academic_allocations.flatten.map(&:allocation_tag_id).flatten : at_id
        allocations_with_acess =  user.allocation_tags_ids_with_access_on('interact','webconferences', false, true)
        allocations_with_acess.include?(nil) || (allocations_with_acess & ats).any?
      )
    )
  end

  def self.all_recordings
    @api = Webconference.bbb_prepare
    response = @api.get_recordings()
    response[:recordings]
  end

  def recordings(recordings = [], at_id = nil)
    meeting_id = get_mettingID(at_id)
    recordings = Webconference.all_recordings if recordings.empty?

    recordings.each do |m|
      return m[:playback][:format][:url] if m[:meetingID] == meeting_id
    end
    return false
  end

  def get_mettingID(at_id = nil)
    ((shared_between_groups || at_id.nil?) ? id.to_s : [at_id.to_s, id.to_s].join('_'))
  end

  def can_remove_records?
    raise 'not_recorded' unless is_recorded?
    raise 'unavailable'  unless Webconference.online?
    raise 'not_ended'    unless is_over?
  end

  def can_destroy?
    raise 'unavailable'  if is_recorded? && !Webconference.online?
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

  def remove_records
    Webconference.remove_record(academic_allocations)
  end
end
