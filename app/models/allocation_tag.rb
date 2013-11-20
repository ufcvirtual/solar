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
      :user_id => user_id,
      :status => Allocation_Activated,
      :profiles => {:status => true},
      :allocation_tag_id => self.related
    ).where("(profiles.types & #{Profile_Type_Class_Responsible})::boolean").uniq.empty?
  end

  ## Deprecated - use related
  def self.find_related_ids(allocation_tag_id)
    AllocationTag.find(allocation_tag_id).related
  end

  def related(args = {all: true, lower: false, upper: false, objects: false})
    option = self.attributes.delete_if {|key, value| key == 'id' or value.nil?}.map {|k,v| k}.first
    lower, upper = [], []

    case option
      when 'group_id'
        if args[:all] or args[:lower]
          lower = [self]
        end

        if args[:all] or args[:upper]
          group = self.group
          upper = [group.offer.allocation_tag, group.curriculum_unit.allocation_tag, group.course.allocation_tag]
        end
      when 'offer_id'
        if args[:all] or args[:lower]
          lower = [self.offer.groups.map(&:allocation_tag).compact.uniq, self]
        end

        if args[:all] or args[:upper]
          offer = self.offer
          upper = [offer.curriculum_unit.allocation_tag, offer.course.allocation_tag]
        end
      when 'curriculum_unit_id'
        if args[:all] or args[:lower]
          uc = self.curriculum_unit
          lower = [uc.offers.map(&:allocation_tag).compact.uniq, uc.groups.map(&:allocation_tag).compact.uniq, self]
        end

        if args[:all] or args[:upper]
          upper = [self]
        end
      when 'course_id'
        if args[:all] or args[:lower]
          course = self.course
          lower = [course.offers.map(&:allocation_tag).compact.uniq, course.groups.map(&:allocation_tag).compact.uniq, self]
        end

        if args[:all] or args[:upper]
          upper = [self]
        end
    end

    at = (lower + upper).flatten.compact.uniq
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

  ##
  # Verifica se o usuário tem bit de aluno no perfil para a allocation_tag
  ##
  def is_student?(user_id)
    allocation = Allocation.find_by_user_id_and_allocation_tag_id(user_id, id)
    return allocation.nil? ? false : (allocation.profile.types & Profile_Type_Student) == Profile_Type_Student
  end

  def self.user_allocation_tag_related_with_class(class_id, user_id)
    related_allocations = AllocationTag.find_related_ids(Group.find(class_id).allocation_tag.id) # allocations relacionadas à turma
    allocation = Allocation.first(:conditions => ["allocation_tag_id IN (?) AND user_id = #{user_id}", related_allocations])
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

  def self.allocation_tag_details(allocation_tag)
    if !allocation_tag.curriculum_unit_id.nil?
      detail = allocation_tag.curriculum_unit.name
    elsif !allocation_tag.offer.nil?
      detail = allocation_tag.offer.course.name + ' | '
      detail = detail + allocation_tag.offer.curriculum_unit.name + ' | '
      detail = detail + allocation_tag.offer.semester.name
    elsif !allocation_tag.group.nil?
      detail = allocation_tag.group.offer.course.name + ' | '
      detail = detail + allocation_tag.group.offer.curriculum_unit.name + ' | '
      detail = detail + allocation_tag.group.offer.semester.name + ' | '
      detail = detail + allocation_tag.group.code
    end
  end

  def self.curriculum_unit_type(allocation_tag)
    if !allocation_tag.curriculum_unit_id.nil?
      allocation_tag.curriculum_unit.curriculum_unit_type.description
    elsif !allocation_tag.offer.nil?
      allocation_tag.offer.curriculum_unit.curriculum_unit_type.description
    elsif !allocation_tag.group.nil?
      allocation_tag.group.offer.curriculum_unit.curriculum_unit_type.description
    else
      ''
    end
  end

  def self.semester_info(allocation_tag)
    if !allocation_tag.offer.nil?
      if allocation_tag.offer.semester.offer_schedule.start_date <= Date.today && 
        allocation_tag.offer.semester.offer_schedule.end_date >= Date.today
        'semester_active ' + allocation_tag.offer.semester.name
      else
        allocation_tag.offer.semester.name
      end
    elsif !allocation_tag.group.nil?
      if allocation_tag.group.offer.semester.offer_schedule.start_date <= Date.today && 
        allocation_tag.group.offer.semester.offer_schedule.end_date >= Date.today
        'semester_active ' + allocation_tag.group.offer.semester.name 
      else
        allocation_tag.group.offer.semester.name 
      end
    else
      ''
    end
  end

  def info
    self.send(attributes.delete_if {|k, v| v.nil?}.keys.last.gsub(/_id/, '')).try(:info)
  end

end
