class AllocationTag < ActiveRecord::Base

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :offer
  belongs_to :group

  has_many :schedule_events
  has_many :allocations,          dependent: :destroy
  has_many :academic_allocations, dependent: :restrict # nao posso deletar uma ferramenta academica se tiver conteudo

  has_many :users,  through: :allocations, uniq: true
  has_many :offers, through: :curriculum_unit

  has_many :groups, finder_sql: Proc.new {
    if not group_id.nil?
      %Q{ SELECT * FROM groups WHERE id = #{group_id} }
    elsif not offer_id.nil?
      %Q{ SELECT * FROM groups WHERE offer_id = #{offer_id} }
    elsif not curriculum_unit_id.nil?
      %Q{ SELECT DISTINCT t1.* FROM groups AS t1 JOIN offers AS t2 ON t2.id = t1.offer_id WHERE t2.curriculum_unit_id = #{curriculum_unit_id} }
    elsif not course_id.nil?
      %Q{ SELECT DISTINCT t1.* FROM groups AS t1 JOIN offers AS t2 ON t2.id = t1.offer_id WHERE t2.course_id = #{course_id} }
    end
  }

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
    allocation_tag_id.nil? ? nil : AllocationTag.find(allocation_tag_id).related
  end

  def related(args = {all: true, lower: false, upper: false, objects: false})
    option = self.attributes.delete_if {|key, value| key == 'id' or value.nil?}.map {|k,v| k}.first
    lower, upper, sibblings = [], [], []

    case option
      when 'group_id'
        if args[:all] or args[:upper]
          group = self.group
          upper = [group.offer.allocation_tag, group.curriculum_unit.try(:allocation_tag), group.course.try(:allocation_tag)]
        end
      when 'offer_id'
        lower = [self.offer.groups.map(&:allocation_tag).compact.uniq] if args[:all] or args[:lower]

        if args[:all] or args[:upper]
          offer = self.offer
          upper = [offer.curriculum_unit.try(:allocation_tag), offer.course.try(:allocation_tag)]
        end
      when 'curriculum_unit_id'
        if args[:all] or args[:lower]
          uc    = self.curriculum_unit
          lower = [uc.offers.map(&:allocation_tag).compact.uniq, uc.groups.map(&:allocation_tag).compact.uniq]
          sibblings = [uc.offers.map(&:course).compact.map(&:allocation_tag)]
        end
      when 'course_id'
        if args[:all] or args[:lower]
          course = self.course
          lower  = [course.offers.map(&:allocation_tag).compact.uniq, course.groups.map(&:allocation_tag).compact.uniq]
          sibblings = [course.offers.map(&:curriculum_unit).compact.map(&:allocation_tag)]
        end
    end

    at = ([self] + lower + upper + sibblings).flatten.compact.uniq
    return at if args[:objects]
    return at.map(&:id)
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

  def self.allocation_tag_details(allocation_tag, split = false)
    not_specified = I18n.t("users.profiles.not_specified")

    return not_specified if allocation_tag.nil?

    detail = ''
    if !allocation_tag.curriculum_unit_id.nil?
      detail  = allocation_tag.curriculum_unit.name
      uc_type = allocation_tag.curriculum_unit.curriculum_unit_type.description
    elsif !allocation_tag.course_id.nil?
      detail = allocation_tag.course.name
    elsif !allocation_tag.offer.nil?
      offer   = allocation_tag.offer
      detail  = [offer.course.try(:name), offer.curriculum_unit.try(:name), offer.semester.name].join(" | ") unless offer.nil?
      uc_type = offer.curriculum_unit.try(:curriculum_unit_type).try(:description) unless offer.nil?
    elsif !allocation_tag.group.nil?
      offer   = allocation_tag.group.offer
      detail  = [offer.course.try(:name), offer.curriculum_unit.try(:name), offer.semester.name, allocation_tag.group.code].join(" | ") unless offer.nil?
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
      selected   = "GROUP"
      groups_ids = params[:groups_id].split(" ")
      offer_id   =  Group.find(groups_ids.first).offer.id
      allocation_tags_ids = AllocationTag.where(group_id: groups_ids).map(&map.to_sym)
    end

    allocation_tags_ids = [nil] if allocation_tags_ids.empty?

    {allocation_tags: allocation_tags_ids.flatten, selected: selected, offer_id: offer_id}
  end

end
