class AllocationTag < ActiveRecord::Base

  has_many :allocations
  has_many :lessons
  has_many :discussions
  has_many :schedule_events
  has_many :assignments

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :offer
  belongs_to :group

  def self.find_all_groups(allocations)
    query = <<SQL
         SELECT t2.id, t2.code, t3.semester
           FROM allocation_tags AS t1
           JOIN groups          AS t2 ON t1.group_id = t2.id
           JOIN offers          AS t3 ON t2.offer_id = t3.id
          WHERE t1.group_id IS NOT NULL
            AND t1.id IN (#{allocations})
SQL

    Group.find_by_sql(query)
  end

  def is_user_class_responsible?(user_id)
    related_allocations_tags = AllocationTag.find_related_ids(id)
    user_is_class_responsible = false

    # Pesquisa pelas allocations relacionadas ao usuário que possua um perfil de tipo igual a 'Profile_Type_Class_Responsible'
    query = <<SQL
          SELECT DISTINCT allocation.allocation_tag_id
            FROM profiles      AS profile
            JOIN allocations   AS allocation ON allocation.profile_id = profile.id AND allocation.user_id = #{user_id} AND allocation.status = 1
           WHERE profile.types = #{Profile_Type_Class_Responsible} AND profile.status = true
SQL

    # Verificação se a allocation_tag de cada allocation retornada pelo query está inclusa nas allocations_tags relacionadas
    for allocation in Allocation.find_by_sql(query)
      user_is_class_responsible = true if related_allocations_tags.include?(allocation.allocation_tag_id)
      break if user_is_class_responsible
    end

    return user_is_class_responsible
  end

  ## Deprecated - use related
  def self.find_related_ids(allocation_tag_id)
    AllocationTag.find(allocation_tag_id).related
  end

  def related
    at_obj = self.attributes
    at_obj.delete('id')
    at = at_obj.select {|k,v| not v.nil? }

    atgs = case at.keys.first.to_s
      when 'group_id'
        groups_related(Group.find(at['group_id']))
      when 'offer_id'
        offers_related(Offer.find(at['offer_id']), down = true)
      when 'curriculum_unit_id'
        curriculum_units_related(CurriculumUnit.find(at['curriculum_unit_id']), down = true)
      when 'course_id'
        courses_related(course.find(at['course_id']), down = true)
    end

    [self.id, atgs].flatten.compact.uniq.sort
  end

  private

  ##
  # Metodos de relacionamento entre allocation_tags
  ##

  def groups_related(group)
    offers_related(group.offer)
  end

  def offers_related(offer, down = false)
    begin
      at_offer = [offer.allocation_tag.id]
    rescue
      at_offer = []
    end

    at_groups = AllocationTag.where(:group_id => offer.groups.map(&:id)).map(&:id) if not at_offer.compact.empty? and down
    at_uc = curriculum_units_related(offer.curriculum_unit)
    at_c = courses_related(offer.course)

    [at_groups] + at_offer + [at_uc] + [at_c]
  end

  def curriculum_units_related(curriculum_unit, down = false)
    begin
      at_uc = [curriculum_unit.allocation_tag.id]
    rescue
      at_uc = []
    end

    if not at_uc.compact.empty? and down
      offers = curriculum_unit.offers.map(&:id)
      at_offers = AllocationTag.where(:offer_id => offers).map(&:id)

      groups = Group.where(:offer_id => offers).map(&:id)
      at_groups = AllocationTag.where(:group_id => groups).map(&:id)
    end

    [at_groups] + [at_offers] + at_uc
  end

  def courses_related(course, down = false)
    begin
      at_c = [course.allocation_tag.id]
    rescue
      at_c = []
    end

    if not at_c.compact.empty? and down
      offers = course.offers.map(&:id)
      at_offers = AllocationTag.where(:offer_id => offers).map(&:id)

      groups = Group.where(:offer_id => offers).map(&:id)
      at_groups = AllocationTag.where(:group_id => groups).map(&:id)
    end

    [at_groups] + [at_offers] + at_c
  end

end
