require 'active_support/concern'
require 'bigbluebutton_api'

module Bbb
  extend ActiveSupport::Concern

  def verify_quantity_users( allocation_tags_ids = [])
    query = "(initial_time BETWEEN ? AND ?) OR ((initial_time + (interval '1 minutes')*duration) BETWEEN ? AND ?) OR (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration))) OR (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration)))"
    end_time       = initial_time + duration.minutes
    webconferences = Webconference.where(query, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    assignment_webconferences = AssignmentWebconference.where(query, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    webconferences            << self unless self.class == AssignmentWebconference || webconferences.include?(self)
    assignment_webconferences << self unless self.class == Webconference || assignment_webconferences.include?(self)

    unless webconferences.empty? && assignment_webconferences.empty?
      ats      = webconferences.map(&:allocation_tags).flatten.map(&:related).flatten
      ats      << allocation_tags_ids if allocation_tags_ids.any? && !webconferences.include?(self)
      students = 0
      ats.flatten.each do |at|
        allocations = Allocation.find_by_sql <<-SQL
          SELECT COUNT(allocations.id)
          FROM allocations
          JOIN profiles ON profiles.id = allocations.profile_id
          WHERE
            cast( profiles.types & #{Profile_Type_Student} as boolean )
          AND
            allocations.allocation_tag_id = #{at}
          AND 
            allocations.status = 1;
        SQL
      students += allocations.first['count'].to_i
      end

      students += assignment_webconferences.map(&:academic_allocation_user).flatten.map(&:users_count).flatten.sum unless assignment_webconferences.empty?
      
      if students > YAML::load(File.open('config/webconference.yml'))['max_simultaneous_users']
        errors.add(:initial_time, I18n.t("#{self.class.to_s.tableize}.error.limit"))
        raise false
      end
    end
  end

  def verify_quantity_users_per_server(sv)
    query = "(server = ?) AND
             (
                (initial_time BETWEEN ? AND ?) OR
                (
                  (initial_time + (interval '1 minutes')*duration) BETWEEN ? AND ?) OR
                  (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration))) OR
                  (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration)
                  )
                )
              )"
    end_time       = initial_time + duration.minutes
    webconferences = Webconference.where(query, sv, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    assignment_webconferences = AssignmentWebconference.where(query, sv, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    webconferences            << self unless self.class == AssignmentWebconference || webconferences.include?(self)
    assignment_webconferences << self unless self.class == Webconference || assignment_webconferences.include?(self)

    unless webconferences.empty? && assignment_webconferences.empty?
      ats      = webconferences.map(&:allocation_tags).flatten.map(&:related).flatten
      students = 0
      ats.flatten.each do |at|
        allocations = Allocation.find_by_sql <<-SQL
          SELECT COUNT(allocations.id)
          FROM allocations
          JOIN profiles ON profiles.id = allocations.profile_id
          WHERE
            cast( profiles.types & #{Profile_Type_Student} as boolean )
          AND
            allocations.allocation_tag_id = #{at}
          AND
            allocations.status = 1;
        SQL
      students += allocations.first['count'].to_i
      end
      students += assignment_webconferences.map(&:academic_allocation_user).flatten.map(&:users_count).flatten.sum unless assignment_webconferences.empty?
      students
    end
  end

  def cant_change_date
    errors.add(:initial_time, I18n.t("#{self.class.to_s.tableize}.error.date")) if (Time.now > (initial_time_was+duration_was.minutes))
  end

  def verify_time(allocation_tags_ids = [])
    query    = "(initial_time BETWEEN ? AND ?) OR ((initial_time + (interval '1 minutes')*duration) BETWEEN ? AND ?) OR (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration))) OR (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration)))"
    end_time = initial_time + duration.minutes
    
    objs = if respond_to?(:academic_allocation_user_id)
      AssignmentWebconference.where(academic_allocation_user_id: academic_allocation_user_id).where(query, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    else
      Webconference.joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids, academic_tool_type: 'Webconference' }).where(query, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    end

    if (objs - [self]).any?
      errors.add(:initial_time, I18n.t("#{self.class.to_s.tableize}.error.time_and_place"))
      raise false
    end
  end

  def bbb_online?(api = nil)
    Timeout::timeout(5) do
      api = bbb_prepare if api.nil?
      url  = URI(api.url)
      response = Net::HTTP.get_response(url)
      return (Net::HTTPSuccess === response)
    end
  rescue
    false
  end

  def bbb_prepare
    choose_server if server.blank?
    Timeout::timeout(5) do
      @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
      bbb  = @config['servers'][@config['servers'].keys[server]]
      debug   = @config['debug']
      BigBlueButton::BigBlueButtonApi.new(bbb['url'], bbb['salt'], bbb['version'].to_s, debug)
    end
  rescue
    false
  end

  def self.bbb_prepare(server)
    Timeout::timeout(5) do
      @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
      bbb  = @config['servers'][@config['servers'].keys[server]]
      debug   = @config['debug']
      BigBlueButton::BigBlueButtonApi.new(bbb['url'], bbb['salt'], bbb['version'].to_s, debug)
    end
  rescue
    false
  end

  def count_servers
     Timeout::timeout(5) do
      @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
      @config['servers'].count
    end
  rescue
    false
  end

  def bbb_all_recordings(api = nil)
    api = bbb_prepare if api.nil?
    raise "offline"   if api.nil?
    response = api.get_recordings
    response[:recordings]
  rescue => error
    return []
  end

  def get_meetings(api = nil)
    api = bbb_prepare if api.nil?
    raise "offline"   if api.nil?
    api.get_meetings[:meetings].collect{|m| m[:meetingID]}
  rescue => error
    return []
  end

  def status(at_id = nil)
    case
    when on_going? then I18n.t('webconferences.list.in_progress')
    when (Time.now < initial_time) then I18n.t('webconferences.list.scheduled')
    when !is_over? then I18n.t('webconferences.list.processing')
    else
      I18n.t('webconferences.list.finish')
    end
  end

  def recordings(recordings = [], at_id = nil)
    meeting_id = get_mettingID(at_id)
    recordings = bbb_all_recordings if recordings.blank?
    common_recordings = []

    recordings.each do |m|
      common_recordings << m if m[:meetingID] == meeting_id
    end

    return common_recordings
    return false
  end

  def remove_record(recordId, at=nil)
    raise 'error' if !at.nil? && at.class == Array
    raise 'copy' unless self.class.to_s != 'Webconference' || origin_meeting_id.blank?
    ids = recordings([], at).collect{|a| a[:recordID]}
    raise CanCan::AccessDenied unless ids.include?(recordId)
    api = bbb_prepare
    api.delete_recordings(recordId)
  end

  def self.get_recording_url(recording)
    recording[:playback][:format][:url]
  end

  def started?
    Time.now >= initial_time
  end

  def on_going?
    Time.now.between?(initial_time, initial_time+duration.minutes)
  rescue
    (opened == 't' && closed == 'f')
  end

  def is_over?
    Time.now > (initial_time+duration.minutes+15.minutes)
  end

  def over?
    Time.now > (initial_time+duration.minutes)
  end

  def can_destroy?
    raise raise CanCan::AccessDenied if respond_to?(:is_onwer?) && !is_onwer?
    raise 'date_range'               if respond_to?(:in_time?)  && !in_time?
    raise 'unavailable'              unless bbb_online?
    raise 'not_ended'                unless is_over?
  end

  def can_remove_records?
    raise raise CanCan::AccessDenied if respond_to?(:is_onwer?) && !is_onwer?
    raise 'date_range'               if respond_to?(:in_time?)  && !in_time?
    raise 'unavailable'              unless bbb_online?
    raise 'not_ended'                unless is_over?
    raise 'copy'                     unless self.class.to_s != 'Webconference' || origin_meeting_id.blank?
  end

  def meeting_info(user_id, at_id = nil, meetings = nil)
    raise nil unless on_going?
    meeting_id = get_mettingID(at_id)
    @api       = bbb_prepare
    meetings   = meetings || @api.get_meetings[:meetings].collect{|m| m[:meetingID]}
    raise nil unless !meetings.nil? && meetings.include?(meeting_id)
    response   = @api.get_meeting_info(meeting_id, Digest::MD5.hexdigest((title rescue name)+meeting_id))
    response[:participantCount]
  rescue
    0
  end

end