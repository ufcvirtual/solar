require 'bigbluebutton_api'

class Webconference < ActiveRecord::Base

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :moderator, class_name: "User", foreign_key: :user_id

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  validates :title, :initial_time, :duration, presence: true
  validates :title, :description, length: {maximum: 255}

  def can_access?
    Time.now.between?(initial_time, initial_time+duration.minutes)
  end

  def link_to_join(user)
    if can_access?
      ActionController::Base.helpers.link_to(title, bbb_join(user), target: "_blank")
    else
      title
    end
  end

  def is_meeting_running(meeting_id)
    @api.is_meeting_running?(meeting_id)
  end


  def status
    if can_access?
       I18n.t(:in_progress, scope: [:webconferences, :list])
    elsif is_recorded?
      if Time.now > (initial_time+duration.minutes+5)
        ActionController::Base.helpers.link_to(I18n.t(:play, scope: [:webconferences, :list]), recordings(), target: "_blank")
      else
        I18n.t(:processing, scope: [:webconferences, :list])
      end
    else
     I18n.t(:finish, scope: [:webconferences, :list])
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).order("initial_time, title")
  end

  def responsible?(user_id)
    not(allocation_tags.map{ |at| at.is_responsible?(user_id) }.include?(false))
  end

  def bbb_prepare
    @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
    server = @config['servers'][@config['servers'].keys.first]

    BigBlueButton::BigBlueButtonApi.new(server['url'], server['salt'], server['version'].to_s, true)
  end

  def bbb_join(user)
    meeting_name = unless groups.empty?
      groups.map(&:code).join(", ")
    else
      o = offers.first
      "#{o.curriculum_unit.name}-#{o.semester.name}"
    end

    meeting_id = "#{meeting_name}-#{id}"
    meeting_name = "#{title} (#{meeting_name})"
    moderator_name = "#{user.name}*"
    attendee_name = user.name


    options = {
      moderatorPW: Digest::MD5.hexdigest("#{meeting_id}"),
      attendeePW: Digest::MD5.hexdigest(id.to_s),
      welcome: description,
      duration: duration,
      record: is_recorded,
      logoutURL: Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: 35
    }

    @api = bbb_prepare
    @api.create_meeting(meeting_name, meeting_id, options) unless @api.is_meeting_running?(meeting_id)

    if (responsible?(user.id))
      @api.join_meeting_url(meeting_id, moderator_name, options[:moderatorPW])
    else
      @api.join_meeting_url(meeting_id, attendee_name, options[:attendeePW])
    end
  end

  def recordings()
    meeting_name = unless groups.empty?
      groups.map(&:code).join(", ")
    else
      o = offers.first
      "#{o.curriculum_unit.name}-#{o.semester.name}"
    end

    meeting_id = "#{meeting_name}-#{id}"

    @api = bbb_prepare

    response = @api.get_recordings
    response[:recordings].each do |m|
      if m[:meetingID] == meeting_id
        playback = m[:playback]
        format = playback[:format]
        url = format[:url]
        return url
      end
    end
    return "http://"
  end

end
