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

      students += assignment_webconferences.map(&:sent_assignment).flatten.map(&:users_count).flatten.sum unless assignment_webconferences.empty?
      
      if students > YAML::load(File.open('config/webconference.yml'))['max_simultaneous_users']
        errors.add(:initial_time, I18n.t("#{self.class.to_s.tableize}.error.limit"))
        raise false
      end
    end
  end

  def cant_change_date
    errors.add(:initial_time, I18n.t("#{self.class.to_s.tableize}.error.date")) if is_recorded_was && (Time.now > (initial_time_was+duration_was.minutes))
  end

  def verify_time(allocation_tags_ids = [])
    query    = "(initial_time BETWEEN ? AND ?) OR ((initial_time + (interval '1 minutes')*duration) BETWEEN ? AND ?) OR (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration))) OR (? BETWEEN initial_time AND ((initial_time + (interval '1 minutes')*duration)))"
    end_time = initial_time + duration.minutes
    
    objs = if respond_to?(:sent_assignment_id)
      AssignmentWebconference.where(sent_assignment_id: sent_assignment_id).where(query, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    else
      Webconference.joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids, academic_tool_type: 'Webconference' }).where(query, initial_time, end_time, initial_time, end_time, initial_time, end_time)
    end
    
    if (objs - [self]).any?
      errors.add(:initial_time, I18n.t("#{self.class.to_s.tableize}.error.time_and_place"))
      raise false
    end
  end

  def bbb_online?
    api = bbb_prepare
    url  = URI(api.url)
    response = Net::HTTP.get_response(url)
    return (Net::HTTPSuccess === response)
  rescue
    false
  end

  def bbb_prepare
    @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
    server  = @config['servers'][@config['servers'].keys.first]
    debug   = @config['debug']
    BigBlueButton::BigBlueButtonApi.new(server['url'], server['salt'], server['version'].to_s, debug)
  end

  def self.bbb_prepare
    @config = YAML.load_file(File.join(Rails.root.to_s, 'config', 'webconference.yml'))
    server  = @config['servers'][@config['servers'].keys.first]
    debug   = @config['debug']
    BigBlueButton::BigBlueButtonApi.new(server['url'], server['salt'], server['version'].to_s, debug)
  end

  def bbb_all_recordings
    @api = bbb_prepare
    response = @api.get_recordings()
    response[:recordings]
  end

  def get_meetings
    @api = bbb_prepare
    @api.get_meetings[:meetings].collect{|m| m[:meetingID]}
  end

  def status(recordings = [], at_id = nil)
    case
    when on_going? then I18n.t(:in_progress, scope: [:webconferences, :list])
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

  def recordings(recordings = [], at_id = nil)
    meeting_id = get_mettingID(at_id)
    recordings = bbb_all_recordings if recordings.blank?

    recordings.each do |m|
      return m[:playback][:format][:url] if m[:meetingID] == meeting_id
    end
    return false
  end

  def on_going?
    Time.now.between?(initial_time, initial_time+duration.minutes)
  end

  def is_over?
    Time.now > (initial_time+duration.minutes+5.minutes)
  end

  def over?
    Time.now > (initial_time+duration.minutes)
  end

  def can_destroy?
    raise raise CanCan::AccessDenied if respond_to?(:is_onwer?) && !is_onwer?
    raise 'date_range'               if respond_to?(:in_time?)  && !in_time?
    raise 'unavailable'              if is_recorded? && !bbb_online?
    raise 'not_ended'                if on_going? || (is_recorded? && !is_over?)
  end

  def can_remove_records?
    raise raise CanCan::AccessDenied if respond_to?(:is_onwer?) && !is_onwer?
    raise 'date_range'               if respond_to?(:in_time?)  && !in_time?
    raise 'not_recorded'             unless is_recorded?
    raise 'unavailable'              unless bbb_online?
    raise 'not_ended'                if on_going? || (is_recorded? && !is_over?)
  end

  def meeting_info(user_id, at_id = nil, meetings = nil)
    raise nil unless on_going?
    meeting_id = get_mettingID(at_id)
    @api       = bbb_prepare
    meetings   = meetings || @api.get_meetings[:meetings].collect{|m| m[:meetingID]}
    raise nil unless !meetings.nil? && meetings.include?(meeting_id)
    response   = @api.get_meeting_info(meeting_id, Digest::MD5.hexdigest(title+meeting_id))
    response[:participantCount]
  rescue
    0
  end

end