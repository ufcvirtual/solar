class AllocationTag < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :course
  belongs_to :curriculum_unit_type
  belongs_to :curriculum_unit
  belongs_to :offer
  belongs_to :group

  has_many :schedule_events
  has_many :allocations, dependent: :destroy
  has_many :academic_allocations, dependent: :restrict # nao posso deletar uma ferramenta academica se tiver conteudo

  has_many :users, through: :allocations, uniq: true

  has_many :savs, dependent: :destroy

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

  def is_responsible?(user_id)
    check_if_user_has_profile_type(user_id)
  end

  def is_observer_or_responsible?(user_id)
    check_if_user_has_profile_type(user_id, responsible = true, observer = true)
  end

  ## return group, offer, course or curriculum_unit
  def refer_to
    self.attributes.keep_if {|k,v| k != "id" and not(v.nil?)}.keys.first.sub(/\_id/, '')
  end

  def is_student?(user_id)
    allocations.joins(:profile).where(user_id: user_id, status: Allocation_Activated).where("cast(profiles.types & ? as boolean)", Profile_Type_Student).count > 0
  end

  def info
    self.send(refer_to).try(:info)
  end

  def detailed_info
    self.send(refer_to).try(:detailed_info)
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
    I18n.t("users.profiles.not_specified")
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

  ## related functions - begin ##

  def related(args = {})
    args = {lower: false, upper: false, objects: false, sibblings: true}.merge(args)
    args = args.merge({lower: true, upper: true}) if not(args[:lower] or args[:upper])

    academic_tool = refer_to

    result = case academic_tool
    when 'group'
      group_related if args[:upper]
    when 'offer'
      offer_related(args[:lower], args[:upper])
    when 'curriculum_unit', 'course'
      uc_or_course_related(academic_tool, args[:lower], args[:upper], args[:sibblings])
    when 'curriculum_unit_type'
      uc_type_related(args[:sibblings]) if args[:lower]
    end

    result = [self, result].flatten.compact.uniq

    return result if args[:objects]
    return result.map(&:id)
  end

  def lower_related
    related(lower: true)
  end

  def group_related
    association_ids = self.group.association_ids

    query = ["offer_id = :offer_id"]
    query << "course_id = :course_id" unless association_ids[:course_id].nil?
    query << "curriculum_unit_id = :curriculum_unit_id" unless association_ids[:curriculum_unit_id].nil?
    query << "curriculum_unit_type_id = :curriculum_unit_type_id" unless association_ids[:curriculum_unit_type_id].nil?

    self.class.where(query.join(" OR "), association_ids)
  end

  def offer_related(lower = true, upper = true)
    r_offer = self.offer

    r_lower = self.class.where(group_id: r_offer.groups.map(&:id)) if lower
    r_upper = if upper
      association_ids = { course_id: r_offer.course_id, curriculum_unit_id: r_offer.curriculum_unit_id, curriculum_unit_type_id: r_offer.curriculum_unit.try(:curriculum_unit_type_id)}

      query = []
      query << "course_id = :course_id" unless association_ids[:course_id].nil?
      query << "curriculum_unit_id = :curriculum_unit_id" unless association_ids[:curriculum_unit_id].nil?
      query << "curriculum_unit_type_id = :curriculum_unit_type_id" unless association_ids[:curriculum_unit_type_id].nil?

      self.class.where(query.join(" OR "), association_ids)
    end

    [r_lower, r_upper]
  end

  def uc_or_course_related(academic_tool, lower = true, upper = true, sibblings = true)
    if lower
      at_offers = offers.map(&:id).uniq
      at_groups = groups.map(&:id).uniq
    end

    sibling_tool = (academic_tool == 'course') ? CurriculumUnit : Course
    siblings = sibling_tool.joins(:offers).where(offers: {id: at_offers}).map(&:id).uniq if sibblings

    if upper
      uc_type = if (academic_tool == 'course')
        self.send(academic_tool.to_sym).curriculum_unit_types
      else
        [self.send(academic_tool.to_sym).curriculum_unit_type]
      end
    end

    query = []
    query << "offer_id IN (:offer_id) OR group_id IN (:group_id)"    unless at_offers.nil?
    query << "#{sibling_tool.to_s.underscore}_id IN (:siblings)"     unless siblings.nil?
    query << "curriculum_unit_type_id IN (:curriculum_unit_type_id)" unless uc_type.nil?

    association_ids = { offer_id: at_offers, group_id: at_groups, siblings: siblings, curriculum_unit_type_id: uc_type }

    self.class.where(query.join(" OR "), association_ids)
  end

  def uc_type_related(sibblings = true)
    at_offers  = offers.map(&:id).uniq
    at_groups  = groups.map(&:id).uniq
    at_courses = curriculum_unit_type.courses.map(&:id) if sibblings
    at_ucs     = curriculum_unit_type.curriculum_units.map(&:id)

    query = []
    query << "group_id           IN (:group_id)"           unless at_groups.nil?
    query << "offer_id           IN (:offer_id)"           unless at_offers.nil?
    query << "course_id          IN (:course_id)"          unless at_courses.nil?
    query << "curriculum_unit_id IN (:curriculum_unit_id)" unless at_ucs.blank?

    association_ids = { offer_id: at_offers, group_id: at_groups, course_id: at_courses, curriculum_unit_id: at_ucs }

    self.class.where(query.join(" OR "), association_ids)
  end

  ## related functions - end ##

  def self.at_groups_by_offer_id(offer_id, only_id = true)
    joins(:group).where(groups: {offer_id: offer_id}).pluck(:id)
  end

  def self.get_by_params(params, related=false, lower_related=false)
    map_attr = (lower_related ? :lower_related : (related ? :related : :id))

    allocation_tags_ids, selected, offer_id = if not params[:allocation_tags_ids].blank? # o proprio params ja contem as ats

      [params.fetch(:allocation_tags_ids, '').split(' ').flatten.map(&:to_i), params.fetch(:selected, nil), params.fetch(:offer_id, nil)]

    elsif params[:groups_id].blank? # nao informa turma
      if not params[:semester_id].blank? # informa offer
        query = { semester_id: params[:semester_id] }
        query[:curriculum_unit_id] = params[:curriculum_unit_id] unless params[:curriculum_unit_id].blank?
        query[:course_id] = params[:course_id] unless params[:course_id].blank?

        at_offer = joins(:offer).where(offers: query).first

        [at_offer.send(map_attr), 'OFFER', at_offer.offer_id]

      elsif not params[:offer_id].blank? # informa uc

        [find_by_offer_id(params[:offer_id]).send(map_attr), 'OFFER', params[:offer_id]]

      elsif not params[:curriculum_unit_id].blank? # informa uc

        [find_by_curriculum_unit_id(params[:curriculum_unit_id]).send(map_attr), 'CURRICULUM_UNIT', nil]

      elsif not params[:course_id].blank? # informa course

        [find_by_course_id(params[:course_id]).send(map_attr), 'COURSE', nil]

      elsif not params[:curriculum_unit_type_id].blank? # informa curriculum_unit_type

        [find_by_curriculum_unit_type_id(params[:curriculum_unit_type_id]).send(map_attr), 'CURRICULUM_UNIT_TYPE', nil]

      end
    else # informa as turmas
      groups_id = params[:groups_id].split(' ').flatten.map(&:to_i)
      at_groups = find_all_by_group_id(groups_id)

      [at_groups.map(&map_attr).flatten.uniq, 'GROUP', at_groups.first.group.offer_id]
    end

    {allocation_tags: [allocation_tags_ids].flatten, selected: selected, offer_id: offer_id}
  end

  def self.get_participants(allocation_tag_id, params={})
    types, query = [], []
    types << "cast( profiles.types & '#{Profile_Type_Student}' as boolean )"           if params[:students]     or params[:all]
    types << "cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )" if params[:responsibles] or params[:all]
    query << "profile_id IN (#{params[:profiles]})"                                    if params[:profiles]

    User.select("users.*").joins(allocations: :profile).where(allocations: {status: Allocation_Activated, allocation_tag_id: AllocationTag.find(allocation_tag_id).related})
      .where(types.join(" OR ")).where(query.join(" AND ")).uniq
  end

  ### triggers

  trigger.after(:insert) do
    <<-SQL
      -- groups
      IF (NEW.group_id IS NOT NULL) THEN
        INSERT INTO related_taggables (group_id, group_at_id, group_status, offer_id, offer_at_id, semester_id,
                    curriculum_unit_id, curriculum_unit_at_id, course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
          SELECT * FROM related_groups WHERE group_id = NEW.group_id
      -- offers
      ELSIF (NEW.offer_id IS NOT NULL) THEN
        INSERT INTO related_taggables (offer_id, offer_at_id, semester_id, curriculum_unit_id, curriculum_unit_at_id,
                    course_id, course_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id, offer_schedule_id)
          SELECT * FROM related_offers WHERE offer_id = NEW.offer_id;
      -- courses
      ELSIF (NEW.course_id IS NOT NULL) THEN
        INSERT INTO related_taggables (course_id, course_at_id) VALUES (NEW.course_id, NEW.id);
      -- UC
      ELSIF (NEW.curriculum_unit_id IS NOT NULL) THEN
        INSERT INTO related_taggables (curriculum_unit_id, curriculum_unit_at_id, curriculum_unit_type_id, curriculum_unit_type_at_id)
          SELECT * FROM related_curriculum_units WHERE curriculum_unit_id = NEW.curriculum_unit_id;
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

    def check_if_user_has_profile_type(user_id, responsible = true, observer = false)
      query = {
        user_id: user_id,
        status: Allocation_Activated,
        allocation_tag_id: self.related(upper: true),
        profiles: { status: true }
      }

      query_type = []
      query_type << "cast(profiles.types & :responsible as boolean) OR cast(profiles.types & :coord as boolean)" if responsible
      query_type << "cast(profiles.types & :observer as boolean)" if observer

      return false if query_type.empty?

      Allocation.joins(:profile)
        .where(query)
        .where(query_type.join(" OR "), responsible: Profile_Type_Class_Responsible, observer: Profile_Type_Observer, coord: Profile_Type_Coord).count > 0
    end

end
