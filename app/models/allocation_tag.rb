class AllocationTag < ActiveRecord::Base

  belongs_to :course
  belongs_to :curriculum_unit_type
  belongs_to :curriculum_unit
  belongs_to :offer
  belongs_to :group

  has_many :schedule_events
  has_many :allocations, dependent: :destroy
  has_many :academic_allocations, dependent: :restrict_with_error # nao posso deletar uma ferramenta academica se tiver conteudo

  has_many :users, -> { distinct }, through: :allocations

  has_many :savs, dependent: :destroy

  has_many :allocation_tag_owners

  def groups
    case refer_to
      when 'group'
        [group]
      when 'offer'
        Group.where(offer_id: offer_id)
      when 'curriculum_unit'
        Group.joins(:offer).where(offers: {curriculum_unit_id: curriculum_unit_id})
      when 'course'
        Group.joins(:offer).where(offers: {course_id: course_id})
      when 'curriculum_unit_type'
        Group.joins(offer: :curriculum_unit).where(curriculum_units: {curriculum_unit_type_id: curriculum_unit_type_id})
    end
  end

  def offers
    case refer_to
      when 'group'
        Offer.joins(:groups).where(groups: {id: group_id})
      when 'offer'
        [offer]
      when 'curriculum_unit'
        Offer.where(curriculum_unit_id: curriculum_unit_id)
      when 'course'
        Offer.where(course_id: course_id)
      when 'curriculum_unit_type'
        Offer.joins(:curriculum_unit).where(curriculum_units: {curriculum_unit_type_id: curriculum_unit_type_id})
    end
  end

  def get_curriculum_unit
    case refer_to
      when 'group'
        group.curriculum_unit
      when 'offer'
        offer.curriculum_unit
      when 'curriculum_unit'
        self
    end
  end

  def get_course
    case refer_to
      when 'group'
        group.course
      when 'offer'
        offer.course
      when 'course'
        self
    end
  end

  def is_responsible?(user_id)
    check_if_user_has_profile_type(user_id)
  end

  def is_observer_or_responsible?(user_id)
    check_if_user_has_profile_type(user_id, responsible = true, observer = true)
  end

  ## return group, offer, course or curriculum_unit
  def refer_to
    self.attributes.keep_if {|k,v| k != 'id' && k != 'setted_situation' && k != 'situation_date' && k != 'situation_date_ac_id' && !v.nil?}.keys.first.sub(/\_id/, '')
  end

  def is_student?(user_id)
    allocations.joins(:profile).where(user_id: user_id, status: Allocation_Activated).where('cast(profiles.types & ? as boolean)', Profile_Type_Student).count > 0
  end

  def is_student_or_responsible?(user_id)
    check_if_user_has_profile_type(user_id, responsible = true, observer = false, student = true)
  end

  def is_student_or_responsible_or_observer?(user_id)
    check_if_user_has_profile_type(user_id, responsible = true, observer = true, student = true)
  end

  def info
    self.send(refer_to).try(:info)
  end

  def detailed_info
    self.send(refer_to).try(:detailed_info)
  end

  def no_group_info
    if refer_to == 'group'
      self.group.offer.allocation_tag.info
    else
      self.send(refer_to).try(:info)
    end
  end

  def curriculum_unit_types
    case refer_to
      when 'group'
        CurriculumUnitType.joins(curriculum_units: {offers: :groups}).where(groups: {id: group_id}).first.description
      when 'offer'
        CurriculumUnitType.joins(curriculum_units: :offers).where(offers: {id: offer_id}).first.description
      when 'curriculum_unit'
        CurriculumUnitType.joins(:curriculum_units).where(curriculum_units: {id: curriculum_unit_id}).first.description
      when 'course'; ''
      when 'curriculum_unit_type'
        curriculum_unit_type.description
    end
  rescue
    I18n.t('users.profiles.not_specified')
  end

  ## ex: '2014.2 2015.1 semester_active'
  def semester_info
    s_info = case refer_to
    when 'group'
      g_offer = offers.first
      [g_offer.semester.name, ('semester_active' if g_offer.is_active?)]
    when 'offer'
      [offer.semester.name, ('semester_active' if offer.is_active?)]
    when 'curriculum_unit', 'course', 'curriculum_unit_type'
      c_offers  = offers
      semesters = Semester.joins(:offers).where(offers: {id: c_offers.map(&:id)})
      [semesters.map(&:name).uniq.join(' '), ('semester_active' if c_offers.map(&:is_active?).include?(true))]
    end

    s_info.compact.join(' ')
  end

  def related(options = { upper: true, lower: true })
    RelatedTaggable.related(self, options)
  end

  def lower_related
    related(lower: true)
  end

  def upper_related
    related(upper: true)
  end

  def self.at_groups_by_offer_id(offer_id, only_id = true)
    RelatedTaggable.where(offer_id: offer_id).pluck(:group_at_id).uniq.compact
  end

  def verify_offer_period
    offer = offers.first
    return !(offer.end_date < Date.current)
    # return !(offer.end_date < Date.current || offer.start_date > Date.current)
  end

  def self.get_by_params(params, related = false, lower_related = false)
    allocation_tags_ids, selected, offer_id = unless params[:allocation_tags_ids].blank? # o proprio params ja contem as ats
      [params.fetch(:allocation_tags_ids, '').split(' ').flatten.map(&:to_i), params.fetch(:selected, nil), params.fetch(:offer_id, nil)]
    else
      case
        when !params[:groups_id].blank?
          params[:groups_ids] = params[:groups_id].split(" ").flatten.map(&:to_i)
          query = 'group_id IN (:groups_ids)'
          selected = 'GROUP'
          offer = true
        when !params[:semester_id].blank? || !params[:semester].blank?
          query = []
          params.merge!(semester_id: Semester.where(name: params[:semester]).first.try(:id)) unless params[:semester_id]
          raise ActiveRecord::RecordNotFound unless params[:semester_id]
          query << 'semester_id = :semester_id'
          query << (params[:curriculum_unit_id].blank? ? 'curriculum_unit_id IS NULL'  : 'curriculum_unit_id = :curriculum_unit_id') unless (params[:curriculum_unit_id].blank? && params[:curriculum_unit_type_id].to_i == 3)
          query << (params[:course_id].blank? ? 'course_id IS NULL' : 'course_id = :course_id')
          query << 'curriculum_unit_type_id = :curriculum_unit_type_id' if params[:curriculum_unit_type_id]
          query = query.join(" AND ")
          selected = 'OFFER'
          offer = true
        when !params[:offer_id].blank?
          query = []
          query << 'offer_id = :offer_id'
          selected = 'OFFER'
          offer = true
        when !params[:course_id].blank?
          query = 'course_id = :course_id'
          selected = 'COURSE'
        when !params[:curriculum_unit_id].blank?
          query = 'curriculum_unit_id = :curriculum_unit_id'
          selected = 'CURRICULUM_UNIT'
        when !params[:curriculum_unit_type_id].blank?
          query = 'curriculum_unit_type_id = :curriculum_unit_type_id'
          selected = 'CURRICULUM_UNIT_TYPE'
      end

      unless query.blank?
        rts = RelatedTaggable.where(query, params.slice(:groups_ids, :offer_id, :semester_id, :course_id, :curriculum_unit_id, :curriculum_unit_type_id))
        raise ActiveRecord::RecordNotFound if rts.empty?

        offer_id = rts.map(&:offer_id).first if offer
        opt = (lower_related ? { lower: true } : ((related || selected.nil?) ? {} : { name: selected.downcase }))
        [rts.map{|rt| rt.at_ids(opt)}.uniq, selected, offer_id]
      end
    end

    { allocation_tags: [allocation_tags_ids].flatten, selected: selected, offer_id: offer_id }
  end

  def get_students
    User.joins(allocations: :profile).where(allocations: {allocation_tag_id: self.id, status: Allocation_Activated}).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
  end

  def self.get_participants(allocation_tag_id, params = { all: true }, scores = false)
    types, query, select, relations, group = [], [], [], [], []
    types << "cast( profiles.types & '#{Profile_Type_Student}' as boolean )"           if params[:students]     || params[:all]
    types << "cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )" if params[:responsibles] || params[:all]
    query << "allocations.profile_id IN (#{params[:profiles]})"                                    if params[:profiles]
    query << "lower(unaccent(users.name)) ~ lower(unaccent('#{params[:user_name]}'))" unless params[:user_name].blank?

    ats = (allocation_tag_id.kind_of?(Array) ? allocation_tag_id : AllocationTag.find(allocation_tag_id).related).flatten.join(',')

    query << "allocations.status = #{Allocation_Activated}"
    query << "allocations.allocation_tag_id IN (#{ats})"

    select << "DISTINCT users.id, COUNT(public_files.id) AS u_public_files, replace(replace(translate(array_agg(distinct profiles.name)::text,'{}', ''),'\"', ''),',',', ') AS profile_name"

    relations << <<-SQL
      LEFT JOIN allocations ON users.id    = allocations.user_id
      LEFT JOIN allocations grades ON users.id    = grades.user_id AND grades.final_grade IS NOT NULL AND grades.allocation_tag_id IN (#{ats})
      LEFT JOIN allocations wh     ON users.id    = wh.user_id     AND wh.working_hours IS NOT NULL AND wh.allocation_tag_id IN (#{ats})
      LEFT JOIN profiles    ON profiles.id = allocations.profile_id
      LEFT JOIN public_files ON public_files.user_id = users.id AND public_files.allocation_tag_id IN (#{ats})
    SQL

    group << 'users.id, users.name'

    if scores
      msg_query = Message.get_query('users.id', 'outbox', ats, { ignore_trash: false, ignore_user: true })

      select << 'users.name, COALESCE(posts.count,0) AS u_posts, COALESCE(posts.count_discussions,0) AS discussions, COALESCE(logs.count,0) AS u_logs, COALESCE(sent_msgs.count,0) AS u_sent_msgs, COALESCE(grades.parcial_grade, 0) AS partial_grade, COALESCE(grades.final_grade, 0) AS u_grade, COALESCE(grades.final_exam_grade, 0) AS af_grade, COALESCE(exams.count,0) AS exams, COALESCE(logs_a.count,0) AS webconferences, COALESCE(assignments.count,0) AS assignments, COALESCE(events.count,0) AS schedule_events, COALESCE(chats.count,0) AS chat_rooms, COALESCE(wh.working_hours, 0) AS working_hours, COALESCE(grades.grade_situation, allocations.grade_situation) AS grade_situation, groups.name AS origin_group_name, groups.code AS origin_group_code, groups.id AS origin_group_id, origin_at.id AS origin_at_id'

      relations << <<-SQL
        LEFT JOIN (
          SELECT  COUNT(DISTINCT exams.id) AS count, academic_allocation_users.user_id AS user_id
          FROM academic_allocation_users
          JOIN academic_allocations ON academic_allocations.id = academic_allocation_users.academic_allocation_id AND academic_allocations.academic_tool_type = 'Exam'
          JOIN exams ON exams.id = academic_allocations.academic_tool_id AND exams.status = TRUE
          WHERE academic_allocations.allocation_tag_id IN (#{ats})
          GROUP BY academic_allocation_users.user_id
        ) exams ON exams.user_id = users.id
        LEFT JOIN (
          SELECT  COUNT(DISTINCT academic_allocations.academic_tool_id) AS count, COALESCE(academic_allocation_users.user_id, gp.user_id) AS user_id
          FROM academic_allocation_users
          JOIN (
           (SELECT assignment_files.academic_allocation_user_id FROM assignment_files)
           UNION
           (SELECT assignment_webconferences.academic_allocation_user_id
           FROM assignment_webconferences)
          ) files ON files.academic_allocation_user_id = academic_allocation_users.id
          JOIN academic_allocations ON academic_allocations.id = academic_allocation_users.academic_allocation_id AND academic_allocations.academic_tool_type = 'Assignment'
          LEFT JOIN group_participants gp ON gp.group_assignment_id = academic_allocation_users.group_assignment_id
          WHERE academic_allocations.allocation_tag_id IN (#{ats})
          GROUP BY COALESCE(academic_allocation_users.user_id, gp.user_id)
        ) assignments ON assignments.user_id = users.id
        LEFT JOIN (
          SELECT COUNT(discussion_posts.id) AS count, COUNT(DISTINCT academic_allocations.academic_tool_id) AS count_discussions, discussion_posts.user_id AS user_id
          FROM discussion_posts
          JOIN academic_allocations ON academic_allocations.id = discussion_posts.academic_allocation_id
          WHERE academic_allocations.allocation_tag_id IN (#{ats})
          AND discussion_posts.draft = 'f'
          GROUP BY discussion_posts.user_id
        ) posts ON posts.user_id = users.id
        LEFT JOIN (
          SELECT COUNT(log_accesses.id) AS count, log_accesses.user_id AS user_id
          FROM log_accesses
          WHERE log_accesses.allocation_tag_id IN (#{ats})
          AND log_accesses.log_type = #{LogAccess::TYPE[:group_access]}
          GROUP BY log_accesses.user_id
        ) logs ON logs.user_id = users.id
        LEFT JOIN (
          SELECT COUNT(messages.id) AS count, user_messages.user_id AS user_id
          FROM messages
          JOIN user_messages ON user_messages.message_id = messages.id
          WHERE #{msg_query}
          GROUP BY user_messages.user_id
        ) sent_msgs ON sent_msgs.user_id = users.id
        LEFT JOIN (
          SELECT COUNT(DISTINCT academic_allocations.academic_tool_id) AS count, log_actions.user_id AS user_id
          FROM log_actions
          JOIN academic_allocations ON academic_allocations.id = log_actions.academic_allocation_id
          WHERE academic_allocations.allocation_tag_id IN (#{ats})
          AND academic_allocations.academic_tool_type = 'Webconference'
          AND log_actions.log_type = #{LogAction::TYPE[:access_webconference]}
          GROUP BY log_actions.user_id
        ) logs_a ON logs_a.user_id = users.id
        LEFT JOIN (
          SELECT  COUNT(DISTINCT academic_allocations.academic_tool_id) AS count, academic_allocation_users.user_id AS user_id
          FROM academic_allocation_users
          JOIN academic_allocations ON academic_allocations.id = academic_allocation_users.academic_allocation_id AND academic_allocations.academic_tool_type = 'ScheduleEvent'
          WHERE academic_allocations.allocation_tag_id IN (#{ats})
          GROUP BY academic_allocation_users.user_id
        ) events ON events.user_id = users.id
        LEFT JOIN (
          SELECT COUNT(DISTINCT academic_allocations.academic_tool_id) AS count, COALESCE(chat_messages.user_id, allocations.user_id) AS user_id
          FROM chat_messages
          JOIN allocations ON allocations.id = chat_messages.allocation_id
          JOIN academic_allocations ON academic_allocations.id = chat_messages.academic_allocation_id AND academic_allocations.academic_tool_type = 'ChatRoom'
          WHERE academic_allocations.allocation_tag_id IN (#{ats})
          GROUP BY COALESCE(chat_messages.user_id, allocations.user_id)
        ) chats ON chats.user_id = users.id
        LEFT JOIN groups ON groups.id = allocations.origin_group_id
        LEFT JOIN allocation_tags AS origin_at ON groups.id = origin_at.group_id
      SQL

      group << 'posts.count, logs.count, sent_msgs.count, COALESCE(grades.parcial_grade, 0), COALESCE(grades.final_grade, 0), COALESCE(grades.final_exam_grade, 0), posts.count_discussions, exams.count, logs_a.count, assignments.count, events.count, chats.count, COALESCE(wh.working_hours, 0), COALESCE(grades.grade_situation, allocations.grade_situation), groups.name, groups.code, groups.id, origin_at.id'
    else
      select << "users.*, replace(replace(translate(array_agg(distinct profiles.name)::text,'{}', ''),'\"', ''),',',', ') AS profile_name"
    end

    User.find_by_sql <<-SQL
      SELECT #{select.join(',')}
      FROM users
        #{relations.join(' ')}
      WHERE (
        #{types.join(' OR ')}
      ) AND (
        #{query.join(' AND ')}
      )
      GROUP BY #{group.join(',')}
      ORDER BY users.name;
    SQL
  end

  def recalculate_students_grades
    ats = lower_related if group.nil?
    alls = allocations.includes(:profile).references(:profile).where(status: Allocation_Activated, allocation_tag_id: (ats || id)).where('cast(profiles.types & ? as boolean) AND (final_grade IS NOT NULL OR working_hours IS NOT NULL)', Profile_Type_Student).references(:profile)
    alls.map(&:calculate_final_grade)
    alls.map(&:calculate_working_hours)
  end

  def set_students_situations(manually = false)
    ats = lower_related if group.nil?
    alls = Allocation.includes(:profile).references(:profile).where(status: Allocation_Activated, allocation_tag_id: (ats || id)).where('cast(profiles.types & ? as boolean) AND final_grade IS NOT NULL', Profile_Type_Student).to_a

    if alls.empty?
      alls = []
      alls << Allocation.includes(:profile).references(:profile).where(status: Allocation_Activated, allocation_tag_id: (ats || id)).where('cast(profiles.types & ? as boolean)', Profile_Type_Student)
    else
      alls << Allocation.includes(:profile).references(:profile).where(status: Allocation_Activated, allocation_tag_id: (ats || id)).where('cast(profiles.types & ? as boolean) AND user_id NOT IN (?)', Profile_Type_Student, alls.map(&:user_id))
    end

    alls.flatten.each do |allocation|
      allocation.set_situation(manually)
    end
  end

  def remove_students_situations
    ats = lower_related if group.nil?
    alls = Allocation.joins(:profile).where(status: Allocation_Activated, allocation_tag_id: (ats || id)).where('cast(profiles.types & ? as boolean) AND grade_situation != 0 AND grade_situation != 6', Profile_Type_Student)
    alls.update_all grade_situation: Allocation::Pending
    update_attributes setted_situation: false
  end

  def can_set_situation_automatically?
    if situation_date.blank?
      last_date = AcademicTool.last_date(id)
      update_attributes(situation_date: last_date[:date], situation_date_ac_id: last_date[:ac_id])
    end

    course = get_course
    uc = get_curriculum_unit

    min_hours = (uc.try(:min_hours) || course.try(:min_hours))
    hours_defined = (!uc.working_hours.blank? && !min_hours.blank?)

    has_passing_grade = !course.blank? && !course.passing_grade.blank?

    return (!setted_situation && (!situation_date.nil? && Date.today >= situation_date) && (has_passing_grade || hours_defined))
  end

  ### triggers

  trigger.after(:insert) do
    <<-SQL
      -- groups
      IF (NEW.group_id IS NOT NULL) THEN
        INSERT INTO related_taggables (group_id, group_at_id, group_status, offer_id, offer_at_id, semester_id,
                    curriculum_unit_id, curriculum_unit_at_id, course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
          SELECT * FROM vw_at_related_groups WHERE group_id = NEW.group_id;
      -- offers
      ELSIF (NEW.offer_id IS NOT NULL) THEN
        INSERT INTO related_taggables (offer_id, offer_at_id, semester_id, curriculum_unit_id, curriculum_unit_at_id,
                    course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
          SELECT * FROM vw_at_related_offers WHERE offer_id = NEW.offer_id;
      -- courses
      ELSIF (NEW.course_id IS NOT NULL) THEN
        INSERT INTO related_taggables (course_id, course_at_id) VALUES (NEW.course_id, NEW.id);
      -- UC
      ELSIF (NEW.curriculum_unit_id IS NOT NULL) THEN
        INSERT INTO related_taggables (curriculum_unit_id, curriculum_unit_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id)
          SELECT * FROM vw_at_related_curriculum_units WHERE curriculum_unit_id = NEW.curriculum_unit_id;
      -- UC type
      ELSIF (NEW.curriculum_unit_type_id IS NOT NULL) THEN
        INSERT INTO related_taggables (curriculum_unit_type_id, curriculum_unit_type_at_id) VALUES (NEW.curriculum_unit_type_id, NEW.id);
      END IF;
    SQL
  end

  trigger.after(:destroy) do
    <<-SQL
      DELETE FROM related_taggables
            WHERE group_at_id = OLD.id
               OR offer_at_id = OLD.id
               OR course_at_id = OLD.id
               OR curriculum_unit_at_id = OLD.id
               OR curriculum_unit_type_at_id = OLD.id;
    SQL
  end

  private

    def check_if_user_has_profile_type(user_id, responsible = true, observer = false, student = false)
      query = {
        user_id: user_id,
        status: Allocation_Activated,
        allocation_tag_id: self.related(upper: true),
        profiles: { status: true }
      }

      query_type = []
      query_type << 'cast(profiles.types & :responsible as boolean) OR cast(profiles.types & :coord as boolean)' if responsible
      query_type << 'cast(profiles.types & :observer as boolean)' if observer
      query_type << 'cast(profiles.types & :student as boolean)' if student

      return false if query_type.empty?

      Allocation.joins(:profile)
        .where(query)
        .where(query_type.join(' OR '), responsible: Profile_Type_Class_Responsible, observer: Profile_Type_Observer, coord: Profile_Type_Coord, student: Profile_Type_Student).count > 0
    end

end
