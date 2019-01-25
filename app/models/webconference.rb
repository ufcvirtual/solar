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

  validate :verify_quantity, if: '!(duration.nil? || initial_time.nil?) && (initial_time_changed? || duration_changed? || new_record?) && merge.nil?'

  validate :verify_offer, unless: 'allocation_tag_ids_associations.blank?'

  def link_to_join(user, at_id = nil, url = false)
    ((on_going? && bbb_online? && have_permission?(user, at_id.to_i)) ? (url ? bbb_join(user, at_id) : ActionController::Base.helpers.link_to((title rescue name), bbb_join(user, at_id), target: '_blank')) : (title rescue name))
  end

  def self.all_by_allocation_tags(allocation_tags_ids, opt = { asc: true }, user_id = nil)
    query  = allocation_tags_ids.include?(nil) ? {} : { academic_allocations: { allocation_tag_id: allocation_tags_ids } }

    select = "users.name AS user_name, academic_allocations.evaluative, academic_allocations.frequency, academic_allocations.frequency_automatic, academic_allocations.max_working_hours, academic_allocations.final_exam, eq_web.title AS eq_name, webconferences.initial_time || '' AS start_hour, webconferences.initial_time + webconferences.duration* interval '1 min' || '' AS end_hour, webconferences.initial_time AS start_date, CASE
      WHEN acu.grade IS NOT NULL OR acu.working_hours IS NOT NULL THEN 'evaluated'
      WHEN (acu.status = 1 OR (acu.status IS NULL AND (academic_allocations.academic_tool_type = 'Webconference' AND log_actions.count > 0))) THEN 'sent'
      when NOW()>webconferences.initial_time AND NOW()<(webconferences.initial_time + webconferences.duration* interval '1 min') then 'in_progress'
      when NOW() < webconferences.initial_time then 'scheduled'
      when (NOW()<webconferences.initial_time + webconferences.duration* interval '1 min' + interval '15 mins') then 'processing'
      else 'finish'
    END AS situation, CASE
        WHEN (acu.comments_count > 0 OR acu.grade IS NOT NULL OR acu.working_hours IS NOT NULL) THEN true
        ELSE
          false
        END AS has_info"

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
    Webconference.remove_record(academic_allocations) if origin_meeting_id.blank? && !server.blank?
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
        if obj.nil?
          obj = Webconference.new attributes.except('id', 'origin_meeting_id').merge!('origin_meeting_id' => meeting_id)
          obj.merge = true
          obj.save
        end
      end

      new_ac = AcademicAllocation.where(allocation_tag_id: to_at, academic_tool_type: 'Webconference', academic_tool_id: (obj.try(:id) || id)).first_or_initialize
      new_ac.merge = true
      new_ac.save

      if over? && !new_ac.nil? && !new_ac.id.nil?
        old_ac = academic_allocations.where(allocation_tag_id: from_at).try(:first) || academic_allocations.where(allocation_tag_id: AllocationTag.find(from_at).related).first
        LogAction.where(log_type: LogAction::TYPE[:access_webconference], academic_allocation_id: old_ac.id).each do |log|
          from_acu = log.academic_allocation_user
          unless from_acu.nil?
            new_acu = AcademicAllocationUser.where(academic_allocation_id: new_ac.id, user_id: log.user_id).first_or_initialize
            new_acu.grade = from_acu.grade # updates grade with most recent copied group
            new_acu.working_hours = from_acu.working_hours
            new_acu.status = from_acu.status
            new_acu.comments_count = from_acu.comments_count
            new_acu.evaluated_by_responsible = from_acu.evaluated_by_responsible
            new_acu.new_after_evaluation = from_acu.new_after_evaluation
            new_acu.merge = true
            new_acu.save
          end

          log = LogAction.where(log.attributes.except('id', 'academic_allocation_id', 'academic_allocation_user_id').merge!(academic_allocation_id: new_ac.id)).first_or_initialize

          log.merge = true
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

  def comments_by_user
    return [] if User.current.blank?
    acu = AcademicAllocationUser.find_one(ac_id, User.current.id)
    return [] if acu.blank?
    acu.comments
  end

  def get_all_recordings_urls(at_id)
    urls = []
    urls << recordings([], at_id).collect{|r| {url: Bbb.get_recording_url(r), start_time: r[:startTime].to_datetime, end_time: r[:endTime].to_datetime} }
    urls.flatten
  end


  # Inicializa as tabelas temporárias usadas no relatório
  def self.drop_and_create_table_temporary_webs_and_access_uab

    Webconference.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_web;
    SQL

    Webconference.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_web_uab;
    SQL

    Webconference.find_by_sql <<-SQL
      DROP TABLE IF EXISTS temp_web_uab_access;
    SQL

    # ac_id | cu_description | server | is_recorded | initial_time
    Webconference.find_by_sql <<-SQL
      CREATE TEMPORARY TABLE temp_web AS SELECT distinct ac.id as ac_id, cu.description as cu_description, web.server, web.is_recorded, web.duration, web.shared_between_groups, web.initial_time FROM webconferences as web
      INNER JOIN academic_allocations AS ac ON ac.academic_tool_id = web.id AND ac.academic_tool_type = 'Webconference'
      INNER JOIN related_taggables AS rt ON rt.group_at_id = ac.allocation_tag_id OR rt.offer_at_id = ac.allocation_tag_id
      LEFT JOIN curriculum_unit_types AS cu ON cu.id = rt.curriculum_unit_type_id
    SQL

    Webconference.find_by_sql <<-SQL
      CREATE TEMPORARY TABLE temp_web_uab AS SELECT distinct ac.id as ac_id, sem.name AS semester, web.initial_time, web.title, u.name AS creator, co.name AS course_name, cu.name AS cu_name FROM webconferences as web
      INNER JOIN academic_allocations AS ac ON ac.academic_tool_id = web.id AND ac.academic_tool_type = 'Webconference'
      INNER JOIN related_taggables AS rt ON rt.group_at_id = ac.allocation_tag_id OR rt.offer_at_id = ac.allocation_tag_id
      INNER JOIN semesters AS sem ON sem.id = rt.semester_id
      LEFT JOIN curriculum_units AS cu ON cu.id = rt.curriculum_unit_id
      LEFT JOIN courses as co ON co.id = rt.course_id
      INNER JOIN users AS u ON u.id = web.user_id
      WHERE rt.curriculum_unit_type_id = 2
    SQL

    Webconference.find_by_sql <<-SQL
      CREATE TEMPORARY TABLE temp_web_uab_access AS SELECT distinct ac_id as ac_id_access, log.user_id as log_user_id FROM temp_web_uab
      LEFT JOIN log_actions AS log ON log.academic_allocation_id = ac_id where log.log_type = 7
    SQL
  end

  # Retorna quantidade total por tipo ("Curso de Extensao", "Curso de Graduacao a Distancia", "Curso de Graduacao Presencial" e "Curso Livre")
  def self.count_per_type()
    sql = "SELECT cu_description, COUNT(DISTINCT ac_id) AS total FROM temp_web
            GROUP BY cu_description
            ORDER BY cu_description"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna quantidade total e efetiva por semestre (UAB)
  def self.count_total_effective
    sql = "SELECT * FROM (
            SELECT semester, COUNT(DISTINCT ac_id) AS total, count(distinct ac_id_access) as efetiva FROM temp_web_uab
            LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
            GROUP BY semester ORDER BY semester desc LIMIT 10
            ) as result
          ORDER BY result ASC"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna quantidade total de acessos únicos por semestre (UAB)
  def self.count_total_access
    sql = "SELECT semester, acessos FROM (
            SELECT COUNT(DISTINCT log_user_id) AS acessos, semester FROM temp_web_uab
            LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
            GROUP BY 2 ORDER BY acessos DESC LIMIT 10
            ) as result
          GROUP BY  1, 2"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna quantidade total nos últimos 12 meses (UAB)
  def self.count_last_12_months
    sql = "SELECT to_char(initial_time,'Mon') || ' ' || extract(year from initial_time) as period, count (DISTINCT ac_id), to_char(initial_time,'MM') AS mon, extract(year from initial_time) as year
            FROM temp_web_uab
            WHERE initial_time > date_trunc('mon', CURRENT_DATE) - INTERVAL '1 year'
            GROUP BY 1,3,4
            ORDER BY year, mon"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna a quantidade total de webconferências (UAB) agendadas para os próximos 6 meses
  def self.count_next_6_months
    sql = "SELECT to_char(initial_time,'Mon') || ' ' || extract(year from initial_time) as period, coalesce(COUNT(DISTINCT ac_id),0), to_char(initial_time,'MM') AS mon, extract(year from initial_time) as year
            FROM temp_web_uab
            WHERE initial_time > CURRENT_DATE + INTERVAL '6 months'
            GROUP BY 1,3,4
            ORDER BY year, mon"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna total agrupado por mês (UAB)
  def self.group_by_month_of_year
    sql = "SELECT to_char(initial_time,'MM'), count (DISTINCT ac_id),
            CASE
              WHEN (to_char(initial_time,'MM'))= '01' THEN 'Janeiro'
              WHEN (to_char(initial_time,'MM'))= '02' THEN 'Fevereiro'
              WHEN (to_char(initial_time,'MM'))= '03' THEN 'Março'
              WHEN (to_char(initial_time,'MM'))= '04' THEN 'Abril'
              WHEN (to_char(initial_time,'MM'))= '05' THEN 'Maio'
              WHEN (to_char(initial_time,'MM'))= '06' THEN 'Junho'
              WHEN (to_char(initial_time,'MM'))= '07' THEN 'Julho'
              WHEN (to_char(initial_time,'MM'))= '08' THEN 'Agosto'
              WHEN (to_char(initial_time,'MM'))= '09' THEN 'Setembro'
              WHEN (to_char(initial_time,'MM'))= '10' THEN 'Outubro'
              WHEN (to_char(initial_time,'MM'))= '11' THEN 'Novembro'
              WHEN (to_char(initial_time,'MM'))= '12' THEN 'Dezembro'
            ELSE '' END AS mes
          FROM temp_web_uab
          GROUP BY 1
          ORDER BY 1"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna total agrupado por hora do dia (UAB)
  def self.group_by_hour_of_day
    sql = "SELECT  to_char(initial_time,'HH24'), count (DISTINCT ac_id)
            FROM temp_web_uab
            GROUP BY 1
            ORDER BY 1"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna total agrupado por dia da semana (UAB)
  def self.group_by_day_of_week
    sql = "SELECT to_char(initial_time,'ID'),
              CASE
              WHEN (to_char(initial_time,'ID'))= '1' THEN 'Segunda'
              WHEN (to_char(initial_time,'ID'))= '2' THEN 'Terça'
              WHEN (to_char(initial_time,'ID'))= '3' THEN 'Quarta'
              WHEN (to_char(initial_time,'ID'))= '4' THEN 'Quinta'
              WHEN (to_char(initial_time,'ID'))= '5' THEN 'Sexta'
              WHEN (to_char(initial_time,'ID'))= '6' THEN 'Sábado'
              WHEN (to_char(initial_time,'ID'))= '7' THEN 'Domingo'
              ELSE '' END AS semana,
              COUNT (DISTINCT ac_id)
          FROM temp_web_uab
          GROUP BY 1, 2
          ORDER BY 1"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna quantidade total por servidor (servidor | qtd de gravações | total | em tempo real | nome)
  def self.count_per_server
    sql = "SELECT server, SUM(case when is_recorded = true then duration end)/60 as duration, count (DISTINCT ac_id), count(distinct (case when now() BETWEEN initial_time AND initial_time + INTERVAL '1 min' * duration then ac_id end)) as real, CASE WHEN server=0 THEN 'BBB 1' WHEN server=1 THEN 'BBB 2' WHEN server=2 THEN 'BBB 3' WHEN server=3 THEN 'BBB 4' WHEN server=4 THEN 'BBB 5' ELSE 'Não definido' END
          FROM temp_web
          GROUP BY 1
          ORDER BY 1"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna quantidade de Gravadas | Compartilhadas | Média de duração
  def self.count_rec_shared_duration
    sql = "SELECT COUNT(DISTINCT (CASE WHEN is_recorded = true THEN ac_id END)) AS recorded,
            COUNT(DISTINCT (CASE WHEN shared_between_groups = true THEN ac_id end)) AS shared,
            REPLACE( round( AVG(duration),2 )::text, '.', ',' ) AS avg_duration,
            COUNT(temp_web) as total
            FROM temp_web"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna média por dia (total) | média por dia (efetivo) | Maximo em um dia | Soma total | Soma efetiva (UAB)
  def self.avg_max_total
    sql = "SELECT REPLACE( round( AVG(qtd),2 )::text, '.', ',' ) as avg_day_total,
            REPLACE( round( AVG(effective),2 )::text, '.', ',' ) as avg_day_effective,
            MAX(effective) as maximo_dia_efetiva, SUM(qtd) as total_uab, SUM(effective) as total_effective, MAX(qtd) as max_day FROM (
            SELECT to_char(initial_time, 'DD Mon YYYY') AS DAY, COUNT (DISTINCT ac_id) AS qtd, count(distinct ac_id_access) AS effective
            FROM temp_web_uab
            LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
            GROUP BY 1 ORDER BY 2
          ) AS result"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna os 10 maiores criadores (UAB)
  def self.top_creators
    sql = "SELECT creator, count (DISTINCT ac_id)
            FROM temp_web_uab
            GROUP BY 1
            ORDER BY 2 DESC LIMIT 10"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna média de acessos | Total de acessos | Máximo de usuários em uma conferência (UAB)
  def self.avg_max_total_access
    sql = "SELECT replace( round( AVG(qtd),2 )::text, '.', ',' ), SUM(qtd), MAX(qtd) FROM (
              SELECT DISTINCT ac_id AS efetiva, COUNT(ac_id_access) AS qtd, to_char(initial_time, 'DD Mon YYYY'), title FROM temp_web_uab
              LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
              GROUP BY 1,3,4 ORDER BY qtd DESC
            ) AS result
          WHERE qtd > 0"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna total por curso/semestre (UAB)
  def self.total_per_course
    sql = "SELECT * FROM (
            SELECT semester,
            count(distinct (case when course_name = 'Licenciatura em Matemática' THEN ac_id END)) AS Matematica,
            count(distinct (case when course_name = 'Letras Espanhol' THEN ac_id END)) AS Espanhol,
            count(distinct (case when course_name = 'Letras Inglês' THEN ac_id END)) AS Ingles,
            count(distinct (case when course_name = 'Letras Português' THEN ac_id END)) AS Portugues,
            count(distinct (case when course_name = 'Licenciatura em Física' THEN ac_id END)) AS Fisica,
            count(distinct (case when course_name = 'Bacharelado em Administração' THEN ac_id END)) AS Administracao,
            count(distinct (case when course_name = 'Licenciatura em Pedagogia' THEN ac_id END)) AS Pedagogia,
            count(distinct (case when course_name = 'Bacharelado em Gestão Pública' THEN ac_id END)) AS Gestao,
            count(distinct (case when course_name = 'Licenciatura em Química' THEN ac_id END)) AS Quimica FROM temp_web_uab
            GROUP BY 1 ORDER BY semester DESC LIMIT 4
            )AS result
          ORDER BY result ASC"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna as 10 disciplinas com mais acessos (UAB)
  def self.access_per_offer
    sql = "SELECT COUNT(DISTINCT log_user_id) AS acessos, cu_name FROM temp_web_uab
            LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
            GROUP BY 2 Order by acessos DESC LIMIT 10"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna as 10 disciplinas com mais webconferẽncias (UAB)
  def self.total_per_offer
    sql = "SELECT COUNT(DISTINCT ac_id) as qtd, cu_name FROM temp_web_uab
            GROUP BY 2 Order by qtd desc limit 10"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna a média de acessos por semeste (UAB)
  def self.avg_access_per_semester
    sql = "SELECT semester, ROUND(AVG(access / NULLIF(webs * 1.0, 0)), 2) AS AVG FROM (
            SELECT DISTINCT ac_id AS efetiva, COUNT(DISTINCT log_user_id) AS access, COUNT(DISTINCT ac_id_access) AS webs, semester FROM temp_web_uab
            LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
            GROUP BY 4,1 ORDER BY 4
            ) AS result
          GROUP BY 1"
    AcademicAllocation.connection.select_all(sql)
  end

  # Retorna total de acessos por curso/semestre (UAB)
  def self.access_per_course
    sql = "SELECT * FROM (
            SELECT semester,
            count(distinct (case when course_name = 'Licenciatura em Matemática' then log_user_id end)) as Matematica,
            count(distinct (case when course_name = 'Letras Espanhol' then log_user_id end)) as Espanhol,
            count(distinct (case when course_name = 'Letras Inglês' then log_user_id end)) as Ingles,
            count(distinct (case when course_name = 'Letras Português' then log_user_id end)) as Portugues,
            count(distinct (case when course_name = 'Licenciatura em Física' then log_user_id end)) as Fisica,
            count(distinct (case when course_name = 'Bacharelado em Administração' then log_user_id end)) as Administracao,
            count(distinct (case when course_name = 'Licenciatura em Pedagogia' then log_user_id end)) as Pedagogia,
            count(distinct (case when course_name = 'Bacharelado em Gestão Pública' then log_user_id end)) as Gestao,
            count(distinct (case when course_name = 'Licenciatura em Química' then log_user_id end)) as Quimica FROM temp_web_uab
            LEFT JOIN temp_web_uab_access ON temp_web_uab_access.ac_id_access = temp_web_uab.ac_id
            GROUP BY 1 ORDER BY semester desc limit 4
            )as result
          ORDER BY result ASC"
    AcademicAllocation.connection.select_all(sql)
  end
end
