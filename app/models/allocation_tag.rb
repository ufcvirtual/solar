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

  def is_user_class_responsible?(user_id)
    not Allocation.
      select(:allocation_tag_id).
      joins(:profile).
      where(
      user_id: user_id,
      status: Allocation_Activated,
      profiles: {status: true},
      allocation_tag_id: (self.nil? ? self : self.related)
    ).where("cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean)").uniq.empty?
  end

  def is_observer_or_responsible?(user_id)
    not Allocation.
      select(:allocation_tag_id).
      joins(:profile).
      where(
      user_id: user_id,
      status: Allocation_Activated,
      profiles: {status: true},
      allocation_tag_id: (self.nil? ? self : self.related)
    ).where("cast(profiles.types & #{Profile_Type_Class_Responsible} as boolean) OR cast(profiles.types & #{Profile_Type_Observer} as boolean)").uniq.empty?
  end

  ## Deprecated - use related
  def self.find_related_ids(allocation_tag_id)
    allocation_tag_id.nil? ? nil : find(allocation_tag_id).related
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

  def unallocate_user_in_related(user_id)
    Allocation.destroy_all(user_id: user_id, allocation_tag_id: self.related)
  end

  def is_only_user_allocated_in_related?(user_id)
    Allocation.
      select(:allocation_tag_id).
      where("user_id != ?", user_id).
      where(:allocation_tag_id => self.related
    ).uniq.empty?
  end

  ## ex: retorna allocation do professor na oferta se tiver checando relacao com uma turma dessa oferta (professor em uma oferta)
  def user_relation_with_this(user)
    relation = allocations.where(user_id: user)
    relation = user.allocations.where(allocation_tag_id: related) if relation.empty?
    relation
  end

  ##
  # Verifica se o usuário tem bit de aluno no perfil para a allocation_tag
  ##
  def is_student?(user_id)
    allocation = Allocation.find_by_user_id_and_allocation_tag_id(user_id, id)
    return allocation.nil? ? false : (allocation.profile.types & Profile_Type_Student) == Profile_Type_Student
  end

  def self.user_allocation_tag_related_with_class(class_id, user_id)
    related_allocations = AllocationTag.find_related_ids(Group.find(class_id).allocation_tag.id) # allocations relacionadas à turma
    allocation = Allocation.first(:conditions => ["allocation_tag_id IN (?) AND user_id = ?", related_allocations, user_id])
    return (allocation.nil? ? nil : allocation.allocation_tag)
  end

  ##
  # Recupera os ids das allocations_tags verificando o curso, uc, oferta e turma passados
  ##
  def self.by_course_and_curriculum_unit_and_offer_and_group(course_id, curriculum_unit_id, offer_id, group_id)
    offer           = Offer.find(offer_id) unless offer_id.nil? or offer_id == "all" or offer_id == 0
    course          = Course.find(course_id) unless course_id.nil? or course_id == "all" or course_id == 0
    curriculum_unit = CurriculumUnit.find(curriculum_unit_id) unless curriculum_unit_id.nil? or curriculum_unit_id == "all" or curriculum_unit_id == 0

    allocations_tags_ids = Array.new

    if group_id != 0 and group_id != "all" # alguma turma específica
      allocations_tags_ids = [Group.find(group_id).allocation_tag.id]
    elsif group_id == "all" # todas as turmas da oferta
      if offer_id != 0 and offer_id != "all" # alguma oferta específica
        allocations_tags_ids = offer.groups.where("status = #{true}").collect{|group| group.allocation_tag.id }  
      elsif offer_id == "all" # todas as ofertas do curso e uc 
        allocations_tags_ids << course.offers.collect{|offer| offer.groups.collect{|group| group.allocation_tag.id}} unless course.nil?
        allocations_tags_ids << curriculum_unit.offers.collect{|offer| offer.groups.collect{|group| group.allocation_tag.id}} unless curriculum_unit.nil?
      end
    else # nenhuma turma selecionada
      if offer_id != 0 and offer_id != "all" # alguma oferta específica
        allocations_tags_ids = offer.allocation_tag.id
      elsif offer_id == "all" # todas as ofertas do curso e uc 
        allocations_tags_ids << course.offers.collect{|offer| offer.allocation_tag.id} unless course.nil?
        allocations_tags_ids << curriculum_unit.offers.collect{|offer| offer.allocation_tag.id} unless curriculum_unit.nil?
      else # nenhuma oferta selecionada
        allocations_tags_ids << course.allocation_tag.id unless course.nil?
        allocations_tags_ids << curriculum_unit.allocation_tag.id unless curriculum_unit.nil?
      end
    end
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

  def self.curriculum_unit_type(allocation_tag)
    not_specified = I18n.t("users.profiles.not_specified")

    return not_specified if allocation_tag.nil?

    if !allocation_tag.curriculum_unit_id.nil?
      allocation_tag.curriculum_unit.curriculum_unit_type.description
    elsif !allocation_tag.offer.nil?
      return not_specified if allocation_tag.offer.curriculum_unit.nil?
      allocation_tag.offer.curriculum_unit.curriculum_unit_type.description
    elsif !allocation_tag.group.nil?
      return not_specified if allocation_tag.group.offer.curriculum_unit.nil?
      allocation_tag.group.offer.curriculum_unit.curriculum_unit_type.description
    else
      ''
    end
  end

  def self.semester_info(allocation_tag)
    case 
      when allocation_tag.nil?; 'always_active '
      when not(allocation_tag.offer.nil?)
        offer  = allocation_tag.offer
        sclass = offer.semester.name
        sclass = [sclass, 'semester_active'].join(" ") if offer.is_active?
      when not(allocation_tag.group.nil?)
        offer  = allocation_tag.group.offer
        sclass = offer.semester.name
        sclass = [sclass, 'semester_active'].join(" ") if offer.is_active?
      when not(allocation_tag.course.nil?)
        offers = allocation_tag.course.offers
        sclass = offers.map(&:semester).map(&:name).uniq.join(" ")
        sclass = [sclass, 'semester_active'].join(" ") if offers.map(&:is_active?).include?(true)
      when not(allocation_tag.curriculum_unit.nil?)
        offers = allocation_tag.curriculum_unit.offers
        sclass = offers.map(&:semester).map(&:name).uniq.join(" ")
        sclass = [sclass, 'semester_active'].join(" ") if offers.map(&:is_active?).include?(true)
      else
        ' '
    end
  end

  def info
    self.send(attributes.delete_if {|k, v| v.nil?}.keys.last.gsub(/_id/, '')).try(:info)
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

end
