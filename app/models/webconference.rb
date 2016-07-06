class Webconference < ActiveRecord::Base
  include Bbb
  include AcademicTool
  include EvaluativeTool

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :moderator, class_name: 'User', foreign_key: :user_id

  before_destroy :can_destroy?, :remove_records

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  validates :title, :initial_time, :duration, presence: true
  validates :title, :description, length: { maximum: 255 }
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  validate :cant_change_date, only: :update, if: 'initial_time_changed? || duration_changed?'

  validate :verify_quantity, if: '!(duration.nil? || initial_time.nil?) && (initial_time_changed? || duration_changed?)', on: :update

  def link_to_join(user, at_id = nil, url = false)
    ((on_going? && bbb_online? && have_permission?(user, at_id.to_i)) ? (url ? bbb_join(user, at_id) : ActionController::Base.helpers.link_to(title, bbb_join(user, at_id), target: '_blank')) : title) 
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
      maxParticipants: YAML::load(File.open('config/webconference.yml'))['max_simultaneous_users']
    }

    @api = bbb_prepare
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
        ats = (shared_between_groups || at_id.nil?) ? academic_allocations.flatten.map(&:allocation_tag_id).flatten : [at_id].flatten
        allocations_with_acess =  user.allocation_tags_ids_with_access_on('interact','webconferences', false, true)
        allocations_with_acess.include?(nil) || (allocations_with_acess & ats).any?
      )
    )
  end

  def get_mettingID(at_id = nil)
    (origin_meeting_id || ((shared_between_groups || at_id.nil?) ? id.to_s : [at_id.to_s, id.to_s].join('_')))
  end

  def self.remove_record(academic_allocations)
    api = Bbb.bbb_prepare

    academic_allocations.each do |academic_allocation|
      webconference = Webconference.find(academic_allocation.academic_tool_id)
      meeting_id    = webconference.get_mettingID(academic_allocation.allocation_tag_id)
      response      = api.get_recordings()
      response[:recordings].each do |m|
        api.delete_recordings(m[:recordID]) if m[:meetingID] == meeting_id
      end
    end
  end

  def can_unbind?(groups = [])
    !(is_over? && is_recorded)
  end

  def remove_records
    Webconference.remove_record(academic_allocations)
  end

  def can_add_group?(ats = [])
    verify_quantity(ats) if ats.any?
    return true
  rescue 
    return false
  end

  def verify_quantity(allocation_tags_ids = [])
    verify_quantity_users(allocation_tags_ids)
    verify_time(allocation_tags_ids)
  end

  def create_copy(to_at, from_at)
    unless (shared_between_groups && allocation_tags.map(&:id).include?(to_at))
      meeting_id = get_mettingID(from_at)
      if is_recorded? && (on_going? || over?)
        objs = Webconference.joins(:academic_allocations).where(attributes.except('id', 'origin_meeting_id', 'created_at', 'updated_at')).where(academic_allocations: { allocation_tag_id: to_at })
        obj = (objs.collect{|obj| obj if obj.get_mettingID(to_at) == meeting_id}).compact.first
        obj = Webconference.create attributes.except('id').merge!(origin_meeting_id: meeting_id) if obj.nil?
      end
      
      new_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Webconference', academic_tool_id: (obj.try(:id) || id)).first_or_create

      if over? && !new_ac.nil? && !new_ac.id.nil?
        old_ac = academic_allocations.where(allocation_tag_id: from_at).try(:first) || academic_allocations.where(allocation_tag_id: AllocationTag.find(from_at).related).first
        LogAction.where(log_type: LogAction::TYPE[:access_webconference], academic_allocation_id: old_ac.id).each do |log|
          LogAction.create log.attributes.except('id', 'academic_allocation_id').merge!(academic_allocation_id: new_ac.id)
        end
      end
    end
  end

  def get_access(acs, at_id)
    LogAction.joins(:allocation_tag, user: [allocations: :profile] ).where(academic_allocation_id: acs, log_type: LogAction::TYPE[:access_webconference], allocations: { allocation_tag_id: at_id }).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean ) OR cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )").select("log_actions.created_at, users.name AS user_name, allocation_tags.id AS at_id, replace(replace(translate(array_agg(distinct profiles.name)::text,'{}', ''),'\"', ''),',',', ') AS profile_name").order('log_actions.created_at ASC').group('log_actions.created_at, users.name, allocation_tags.id')
  end


end
