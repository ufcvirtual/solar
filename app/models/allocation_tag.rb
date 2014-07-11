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

  def related(args = {all: true, lower: false, upper: false, objects: false})
    academic_tool = refer_to

    result = case academic_tool
    when 'group'
      if args[:all] or args[:upper]
        association_ids = self.group.association_ids

        query = ["offer_id = :offer_id"]
        query << "course_id = :course_id" unless association_ids[:course_id].nil?
        query << "curriculum_unit_id = :curriculum_unit_id" unless association_ids[:curriculum_unit_id].nil?

        self.class.where(query.join(" OR "), association_ids)
      end
    when 'offer'
      o = self.offer
      lower = self.class.where(group_id: o.groups.map(&:id)) if args[:all] or args[:lower]

      if args[:all] or args[:upper]
        association_ids = { course_id: o.course_id, curriculum_unit_id: o.curriculum_unit_id }

        query = []
        query << "course_id = :course_id" unless o.course_id.nil?
        query << "curriculum_unit_id = :curriculum_unit_id" unless o.curriculum_unit_id.nil?

        upper = self.class.where(query.join(" OR "), association_ids)
      end

      [lower, upper]
    when 'curriculum_unit', 'course'
      if args[:all] or args[:lower]
        at_offers = self.offers.map(&:id).uniq
        at_groups = self.groups.map(&:id).uniq

        query = ["offer_id IN (:offer_id) OR group_id IN (:group_id)"]

        if academic_tool == 'curriculum_unit'
          siblings = Course.joins(:offers).where(offers: {id: at_offers}).map(&:id).uniq # siblings
          query << "course_id IN (:siblings)" unless siblings.nil?
        else
          siblings = CurriculumUnit.joins(:offers).where(offers: {id: at_offers}).map(&:id).uniq # siblings
          query << "curriculum_unit_id IN (:siblings)" unless siblings.nil?
        end

        association_ids = { offer_id: at_offers, group_id: at_groups, siblings: siblings }

        self.class.where(query.join(" OR "), association_ids)
      end
    end

    result = [self, result].flatten.compact.uniq

    return result if args[:objects]
    return result.map(&:id)
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

  def semester_info
    info = case refer_to
    when 'group'
      g_offer = group.offer
      sclass = [g_offer.semester.name]
      sclass << 'semester_active' if g_offer.is_active?
    when 'offer'
      sclass = [offer.semester.name]
      sclass << 'semester_active' if offer.is_active?
    when 'curriculum_unit', 'course'
      c_offers = offers
      slcass = Semester.joins(:offers).where(offers: {id: c_offers.map(&:id)}).map(&:name).uniq.join(" ")
      sclass << 'semester_active' if c_offers.map(&:is_active?).include?(true)
    end

    info.join(" ")
  end

  def self.allocation_tag_details(allocation_tag, split = false, with_code = false, semester_first = false)
    not_specified = I18n.t("users.profiles.not_specified")

    return not_specified if allocation_tag.nil?

    detail = ''

    if !allocation_tag.curriculum_unit_id.nil?

      detail  = ( with_code ? allocation_tag.curriculum_unit.code_name : allocation_tag.curriculum_unit.name )
      uc_type = allocation_tag.curriculum_unit.curriculum_unit_type.description

    elsif !allocation_tag.course_id.nil?

      detail  = ( with_code ? allocation_tag.course.code_name : allocation_tag.course.name )

    else

      offer  = ( !allocation_tag.offer.nil? ? allocation_tag.offer : allocation_tag.group.offer )
      uc     = offer.curriculum_unit
      course = offer.course

      detail  = if not(offer.nil?) and uc.try(:curriculum_unit_type_id) == 3
        [ (semester_first ? offer.semester.name : nil), (with_code ? course.try(:code_name) : course.try(:name)),
          (semester_first ? nil : offer.semester.name)].compact.join(" | ")
      else
        [ (semester_first ? offer.semester.name : nil), (with_code ? course.try(:code_name) : course.try(:name)),
          (with_code ? uc.try(:code_name) : uc.try(:name)), (semester_first ? nil : offer.semester.name),
          (allocation_tag.group.nil? ? nil : allocation_tag.group.code) ].compact.join(" | ")
      end

      uc_type = offer.curriculum_unit.try(:curriculum_unit_type).try(:description) unless offer.nil?

    end

    if split
      return {course: not_specified, curriculum_unit: not_specified, semester: not_specified, group: not_specified, curriculum_unit_type: not_specified} if detail.nil?
      detail = detail.split(" | ")
      if (detail.size == 1) 
        detail = allocation_tag.course.nil? ? 
          {course: not_specified, curriculum_unit: detail[0], semester: not_specified, group: not_specified, curriculum_unit_type: uc_type}
        : {course: detail[0], curriculum_unit: not_specified, semester: not_specified, group: not_specified, curriculum_unit_type: not_specified}
      else
        detail = {course: detail[0], curriculum_unit: detail[1], semester: detail[2], group: detail[3], curriculum_unit_type: uc_type}
      end
   end

   return detail
  end

  def self.get_by_params(params, all_groups = false, related = false)
    map = related ? "related" : "id"
    allocation_tags_ids = []

    if params.include?(:allocation_tags_ids)
      allocation_tags_ids = (params[:allocation_tags_ids].class == String ? params[:allocation_tags_ids].split(" ") : params[:allocation_tags_ids])
      selected, offer_id  = (params[:selected].blank? ? nil : params[:selected]), (params[:offer_id].blank? ? nil : params[:offer_id])
    elsif params[:groups_id].blank?
      if params.include?(:semester_id) and (not params[:semester_id] == "")
        offer = Offer.where(semester_id: params[:semester_id], course_id: params[:course_id])
        offer = offer.where(curriculum_unit_id: params[:curriculum_unit_id]) if params.include?(:curriculum_unit_id)
        allocation_tags_ids = [offer.first.allocation_tag].map(&map.to_sym)
        selected = "OFFER"
      elsif params.include?(:curriculum_unit_id) and (not params[:curriculum_unit_id] == "")
        allocation_tags_ids = [CurriculumUnit.find(params[:curriculum_unit_id]).allocation_tag].map(&map.to_sym)
        selected = "CURRICULUM_UNIT"
      elsif params.include?(:course_id) and (not params[:course_id] == "")
        allocation_tags_ids = [Course.find(params[:course_id]).allocation_tag].map(&map.to_sym)
        selected = "COURSE"
      end
    else
      selected, groups_ids = "GROUP", params[:groups_id].split(" ")
      allocation_tags_ids  = AllocationTag.where(group_id: groups_ids).map(&map.to_sym)
      offer = [Group.find(groups_ids.try(:first)).try(:offer)] if offer.nil? and not(groups_ids.blank?)
    end

    allocation_tags_ids = [nil] if allocation_tags_ids.empty?

    {allocation_tags: allocation_tags_ids.flatten, selected: selected, offer_id: offer.try(:first).try(:id)}
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
