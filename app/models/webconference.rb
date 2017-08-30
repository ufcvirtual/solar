class Webconference < ActiveRecord::Base

  before_destroy :can_destroy?, :remove_records

  include Bbb
  include AcademicTool
  include EvaluativeTool

  GROUP_PERMISSION = OFFER_PERMISSION = true

  belongs_to :moderator, class_name: 'User', foreign_key: :user_id


  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  validates :title, :initial_time, :duration, presence: true
  validates :title, :description, length: { maximum: 255 }
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  validate :cant_change_date, on: :update, if: 'initial_time_changed? || duration_changed?'
  validate :cant_change_shared, on: :update, if: 'shared_between_groups_changed?'

  validate :verify_quantity, if: '!(duration.nil? || initial_time.nil?) && (initial_time_changed? || duration_changed? || new_record?)'

  validate :verify_offer, if: '!(duration.nil? || initial_time.nil?) && (new_record? || initial_time_changed? || duration_changed?) && !allocation_tag_ids_associations.blank?'

  def link_to_join(user, at_id = nil, url = false)
    ((on_going? && bbb_online? && have_permission?(user, at_id.to_i)) ? (url ? bbb_join(user, at_id) : ActionController::Base.helpers.link_to((title rescue name), bbb_join(user, at_id), target: '_blank')) : (title rescue name)) 
  end

  def self.all_by_allocation_tags(allocation_tags_ids, opt = { asc: true }, user_id = nil)
    query  = allocation_tags_ids.include?(nil) ? {} : { academic_allocations: { allocation_tag_id: allocation_tags_ids } }

    select = "users.name AS user_name, academic_allocations.evaluative, academic_allocations.frequency, academic_allocations.max_working_hours, academic_allocations.final_exam, academic_allocations.support_help AS support_help, eq_web.title AS eq_name, webconferences.initial_time || '' AS start_hour, webconferences.initial_time + webconferences.duration* interval '1 min' || '' AS end_hour, webconferences.initial_time AS start_date, 
    CASE
      WHEN acu.grade IS NOT NULL OR acu.working_hours IS NOT NULL THEN 'evaluated'
      WHEN (acu.status = 1 OR (acu.status IS NULL AND (academic_allocations.academic_tool_type = 'Webconference' AND log_actions.count > 0))) THEN 'sent'
      when NOW()>webconferences.initial_time AND NOW()<(webconferences.initial_time + webconferences.duration* interval '1 min') then 'in_progress'
      when NOW() < webconferences.initial_time then 'scheduled'
      when (NOW()<webconferences.initial_time + webconferences.duration* interval '1 min' + interval '15 mins') then 'processing' 
      else 'finish'
    END AS situation"

    opt.merge!(select2: "webconferences.*, academic_allocations.allocation_tag_id AS at_id, academic_allocations.id AS ac_id, #{select}")
    opt.merge!(select1: "DISTINCT webconferences.id, webconferences.*, NULL AS at_id, NULL AS ac_id, users.name AS user_name, #{select}")

  webconferences = Webconference.joins(:moderator)
                  .joins("JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Webconference'")
                  .joins(" LEFT JOIN
                    (SELECT count(log_actions.id), log_actions.academic_allocation_id FROM log_actions
                      WHERE log_actions.log_type = 7 AND log_actions.user_id = #{user_id.blank? ? 0 : user_id}
                      GROUP BY log_actions.academic_allocation_id ) log_actions ON academic_allocations.id = log_actions.academic_allocation_id
                  ")
                  .joins("LEFT JOIN academic_allocation_users acu ON acu.academic_allocation_id = academic_allocations.id AND acu.user_id = #{user_id.blank? ? 0 : user_id}")
                  .joins("LEFT JOIN academic_allocations eq_ac ON eq_ac.id = academic_allocations.equivalent_academic_allocation_id")
                  .joins("LEFT JOIN webconferences eq_web ON eq_web.id = eq_ac.academic_tool_id AND eq_ac.academic_tool_type = 'Webconference'")
                  .where(query)
    unless user_id.blank?
      opt[:select1] += ', acu.grade, acu.working_hours'
      opt[:select2] += ', acu.grade, acu.working_hours'
    end

    web1 = webconferences.where(shared_between_groups: true)
    web2 = webconferences.where(shared_between_groups: false)

    (web1.select(opt[:select1]) + web2.select(opt[:select2])).sort_by{ |web| (opt[:asc] ? [web.initial_time.to_i, web.title] : [-web.initial_time.to_i, web.title]) }
  end

  def self.groups_codes(id)
    web = Webconference.find(id)
    if web.shared_between_groups
      Group.joins(:allocation_tag).where(allocation_tags: { id: web.academic_allocations.pluck(:allocation_tag_id) }).pluck(:code)
    else
      []
    end
  end

  def responsible?(user_id, at_id = nil)
    ((shared_between_groups || at_id.nil?) ? (allocation_tags.map{ |at| at.is_responsible?(user_id) }.include?(true)) : AllocationTag.find(at_id).is_responsible?(user_id))
  end

   def student_or_responsible?(user_id, at_id = nil)
    ((shared_between_groups || at_id.nil?) ? (allocation_tags.map{ |at| at.is_student_or_responsible?(user_id) }.include?(true)) : AllocationTag.find(at_id).is_student_or_responsible?(user_id))
  end

  def location
    if shared_between_groups
      offer = offers.first
      offer = groups.first.offer if offer.blank?
      offers.first.allocation_tag.info
    else
      at = AllocationTag.find(at_id)
      at.info  
    end
  rescue 
    web = Webconference.find(id)
    offer = web.offers.first
    offer = web.groups.first.offer if offer.blank?
    offer.allocation_tag.info
  end

  def groups_codes
    groups.map(&:code).join(', ') unless groups.empty?
  end

  def bbb_join(user, at_id = nil)
    meeting_id   = get_mettingID(at_id)
    meeting_name = [(title rescue name), location].join(' - ').truncate(100)

    options = {
      moderatorPW: Digest::MD5.hexdigest((title rescue name)+meeting_id),
      attendeePW: Digest::MD5.hexdigest(meeting_id),
      welcome: description + YAML::load(File.open('config/webconference.yml'))['welcome'],
      duration: duration,
      record: true,
      autoStartRecording: is_recorded,
      allowStartStopRecording: true,
      logoutURL: YAML::load(File.open('config/webconference.yml'))['feedback_url'] || Rails.application.routes.url_helpers.home_url.to_s,
      maxParticipants: YAML::load(File.open('config/webconference.yml'))['max_simultaneous_users']
    }

    @api = bbb_prepare
    login_meeting(user, meeting_id, meeting_name, options)
  end

  def login_meeting(user, meeting_id, meeting_name, options)
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
    (origin_meeting_id || ((shared_between_groups || at_id.nil?) ? id.to_s : [at_id.to_s, id.to_s].join('_'))).to_s
  end

  def self.remove_record(academic_allocations)
    academic_allocations.each do |academic_allocation|
      webconference = Webconference.find(academic_allocation.academic_tool_id)
      if webconference.origin_meeting_id.blank?
        api = Bbb.bbb_prepare(webconference.server)
        meeting_id    = webconference.get_mettingID(academic_allocation.allocation_tag_id)
        response      = api.get_recordings()
        response[:recordings].each do |m|
          api.delete_recordings(m[:recordID]) if m[:meetingID] == meeting_id
        end
      end
    end
  end

  def remove_records
    Webconference.remove_record(academic_allocations) if origin_meeting_id.blank?
  end

  def can_add_group?(ats = [])
    if shared_between_groups
      verify_quantity(ats) if ats.any?
    else
      if ats.any?
        !over? && verify_quantity(ats) 
      else 
        !over?
      end
    end

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
      if (on_going? || over?)
        objs = Webconference.joins(:academic_allocations).where(attributes.except('id', 'origin_meeting_id', 'created_at', 'updated_at')).where(academic_allocations: { allocation_tag_id: to_at })
        obj = (objs.collect{|obj| obj if obj.get_mettingID(to_at) == meeting_id}).compact.first
        obj = Webconference.create attributes.except('id').merge!(origin_meeting_id: meeting_id) if obj.nil?
      end
      
      new_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Webconference', academic_tool_id: (obj.try(:id) || id)).first_or_create

      if over? && !new_ac.nil? && !new_ac.id.nil?
        old_ac = academic_allocations.where(allocation_tag_id: from_at).try(:first) || academic_allocations.where(allocation_tag_id: AllocationTag.find(from_at).related).first
        LogAction.where(log_type: LogAction::TYPE[:access_webconference], academic_allocation_id: old_ac.id).each do |log|
          from_acu = log.academic_allocation_user
          unless from_acu.nil?
            new_acu = AcademicAllocationUser.where(academic_allocation_id: new_ac.id, user_id: log.user_id).first_or_initialize
            new_acu.grade = from_acu.grade # updates grade with most recent copied group
            new_acu.working_hours = from_acu.working_hours
            new_acu.status = from_acu.status
            new_acu.new_after_evaluation = from_acu.new_after_evaluation
            new_acu.merge = true
            new_acu.save
          end

          log = LogAction.where(log.attributes.except('id', 'academic_allocation_id', 'academic_allocation_user_id').merge!(academic_allocation_id: new_ac.id)).first_or_initialize

          log.academic_allocation_user_id = new_acu.try(:id)
          log.save
        end
      end
    end
  end

  def get_access(acs, at_id, user_query={})
    LogAction.joins(:academic_allocation, :allocation_tag, user: [allocations: :profile] )
              .joins('LEFT JOIN academic_allocation_users acu ON acu.academic_allocation_id = log_actions.academic_allocation_id AND acu.user_id = log_actions.user_id')
              .joins("LEFT JOIN allocations students ON allocations.id = students.id AND cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
              .where(academic_allocation_id: acs, log_type: LogAction::TYPE[:access_webconference], allocations: { allocation_tag_id: at_id })
              .where(user_query)
              .where("cast( profiles.types & '#{Profile_Type_Student}' as boolean ) OR cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )")
              .select("log_actions.created_at, users.name AS user_name, allocation_tags.id AS at_id, replace(replace(translate(array_agg(distinct profiles.name)::text,'{}', ''),'\"', ''),',',', ') AS profile_name, users.id AS user_id, acu.grade AS grade, acu.working_hours AS wh, 
                CASE 
                WHEN students.id IS NULL THEN false
                ELSE true
                END AS is_student,
                academic_allocations.max_working_hours")
              .order('log_actions.created_at ASC')
              .group('log_actions.created_at, users.name, allocation_tags.id, users.id, acu.grade, acu.working_hours, students.id, academic_allocations.max_working_hours')
  end

  # Retorna a lista com os atendimentos da webconferência (academic_allocation)
  def get_support_attendance(acs)
    LogAction.joins(:user)
             .where(academic_allocation_id: acs, log_type: LogAction::TYPE[:webconferece_support_attendance])
             .select("log_actions.created_at, users.name AS user_name")
             .order('log_actions.created_at ASC')
  end

  def self.update_previous(academic_allocation_id, user_id, academic_allocation_user_id)
    LogAction.where(academic_allocation_id: academic_allocation_id, user_id: user_id, log_type: 7).update_all academic_allocation_user_id: academic_allocation_user_id
  end

  def self.verify_previous(acu_id)
    LogAction.where(academic_allocation_user_id: acu_id).any?
  end

  def cant_change_shared
    errors.add(:shared_between_groups, I18n.t("webconferences.error.shared")) if (Time.now >= initial_time)
  end

  def verify_offer
    offer = AllocationTag.find(allocation_tag_ids_associations).first.offers.first
    errors.add(:initial_time, I18n.t('schedules.errors.offer_end')) if offer.end_date < (initial_time + duration.minutes).to_date
    errors.add(:initial_time, I18n.t('schedules.errors.offer_start')) if offer.start_date > initial_time.to_date
  end

  # Atualiza a academic_allocation (support_help)
  def self.set_status_support_help(academic_allocation_id, status)
    ac = AcademicAllocation.find(academic_allocation_id)
    ac.update_attributes! support_help: status
    ac
  end
end
