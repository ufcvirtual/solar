class AllocationTag < ActiveRecord::Base

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :offer
  belongs_to :group

  has_many :schedule_events
  has_many :allocations, dependent: :destroy
  has_many :academic_allocations, dependent: :restrict # nao posso deletar uma ferramenta academica se tiver conteudo

  has_many :users, through: :allocations, uniq: true

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
    end
  end

  def is_responsible?(user_id)
    check_if_user_has_profile_type(user_id)
  end

  def is_observer_or_responsible?(user_id)
    check_if_user_has_profile_type(user_id, observer = true)
  end

  ## return group, offer, course or curriculum_unit
  def refer_to
    self.attributes.keep_if {|k,v| k != "id" and not(v.nil?)}.keys.first.sub(/\_id/, '')
  end

  ## ex: retorna allocation do professor na oferta se tiver checando relacao com uma turma dessa oferta (professor em uma oferta)
  def user_relation_with_this(user)
    relation = allocations.where(user_id: user)
    relation = user.allocations.where(allocation_tag_id: related) if relation.empty?
    relation
  end

  def is_student?(user_id)
    allocations.joins(:profile).where(user_id: user_id).where("cast(profiles.types & ? as boolean)", Profile_Type_Student).count > 0
  end

  def info
    self.send(refer_to).try(:info)
  end

  def detailed_info
    self.send(refer_to).try(:detailed_info)
  end

  def curriculum_unit_type
    case refer_to
    when 'group'
      CurriculumUnitType.joins(curriculum_units: {offers: :groups}).where(groups: {id: group_id}).first.description
    when 'offer'
      CurriculumUnitType.joins(curriculum_units: :offers).where(offers: {id: offer_id}).first.description
    when 'curriculum_unit'
      CurriculumUnitType.joins(:curriculum_units).where(curriculum_units: {id: curriculum_unit_id}).first.description
    when 'course'; ''
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
    when 'curriculum_unit', 'course'
      c_offers = offers
      semesters = Semester.joins(:offers).where(offers: {id: c_offers.map(&:id)})
      [semesters.map(&:name).uniq.join(' '), ('semester_active' if c_offers.map(&:is_active?).include?(true))]
    end

    s_info.compact.join(' ')
  end

  ## related functions - begin ##

  def related(args = {})
    args = {lower: false, upper: false, objects: false}.merge(args)
    args = args.merge({lower: true, upper: true}) if not(args[:lower] or args[:upper])

    academic_tool = refer_to

    result = case academic_tool
    when 'group'
      group_related if args[:upper]
    when 'offer'
      offer_related(args[:lower], args[:upper])
    when 'curriculum_unit', 'course'
      uc_or_course_related(academic_tool) if args[:lower]
    end

    result = [self, result].flatten.compact.uniq

    return result if args[:objects]
    return result.map(&:id)
  end

  def group_related
    association_ids = self.group.association_ids

    query = ["offer_id = :offer_id"]
    query << "course_id = :course_id" unless association_ids[:course_id].nil?
    query << "curriculum_unit_id = :curriculum_unit_id" unless association_ids[:curriculum_unit_id].nil?

    self.class.where(query.join(" OR "), association_ids)
  end

  def offer_related(lower = true, upper = true)
    r_offer = self.offer

    r_lower = self.class.where(group_id: r_offer.groups.map(&:id)) if lower
    r_upper = if upper
      association_ids = { course_id: r_offer.course_id, curriculum_unit_id: r_offer.curriculum_unit_id }

      query = []
      query << "course_id = :course_id" unless association_ids[:course_id].nil?
      query << "curriculum_unit_id = :curriculum_unit_id" unless association_ids[:curriculum_unit_id].nil?

      self.class.where(query.join(" OR "), association_ids)
    end

    [r_lower, r_upper]
  end

  def uc_or_course_related(academic_tool)
    at_offers = offers.map(&:id).uniq
    at_groups = groups.map(&:id).uniq

    sibling_tool = (academic_tool == 'course') ? CurriculumUnit : Course
    siblings = sibling_tool.joins(:offers).where(offers: {id: at_offers}).map(&:id).uniq

    query = ["offer_id IN (:offer_id) OR group_id IN (:group_id)"]
    query << "#{sibling_tool.to_s.underscore}_id IN (:siblings)" unless siblings.nil?

    association_ids = { offer_id: at_offers, group_id: at_groups, siblings: siblings }

    self.class.where(query.join(" OR "), association_ids)
  end

  ## related functions - end ##

  def self.get_by_params(params, related = false)
    map_attr = related ? :related : :id

    allocation_tags_ids, selected, offer_id = if not params[:allocation_tags_ids].blank? # o proprio params ja contem as ats

      [params.fetch(:allocation_tags_ids, '').split(' ').flatten.map(&:to_i), params.fetch(:selected, nil), params.fetch(:offer_id, nil)]

    elsif params[:groups_id].blank? # nao informa turma
      if not params[:semester_id].blank? # informa offer
        query = { semester_id: params[:semester_id] }
        query[:curriculum_unit_id] = params[:curriculum_unit_id] unless params[:curriculum_unit_id].blank?
        query[:course_id] = params[:course_id] unless params[:course_id].blank?

        at_offer = joins(:offer).where(offers: query).first

        [at_offer.send(map_attr), 'OFFER', at_offer.offer_id]
      elsif not params[:curriculum_unit_id].blank? # informa uc

        [find_by_curriculum_unit_id(params[:curriculum_unit_id]).send(map_attr), 'CURRICULUM_UNIT', nil]

      elsif not params[:course_id].blank? # informa course

        [find_by_course_id(params[:course_id]).send(map_attr), 'COURSE', nil]

      end
    else # informa as turmas
      groups_id = params[:groups_id].split(' ').flatten.map(&:to_i)
      at_groups = find_all_by_group_id(groups_id)

      [at_groups.map(&map_attr).flatten.uniq, 'GROUP', at_groups.first.group.offer_id]
    end

    {allocation_tags: [allocation_tags_ids].flatten, selected: selected, offer_id: offer_id}
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
      query_type << "cast(profiles.types & :responsible as boolean)" if responsible
      query_type << "cast(profiles.types & :observer as boolean)" if observer

      return false if query_type.empty?

      Allocation.joins(:profile)
        .where(query)
        .where(query_type.join(" OR "), responsible: Profile_Type_Class_Responsible, observer: Profile_Type_Observer).count > 0
    end

end
