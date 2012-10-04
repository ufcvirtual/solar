class AllocationTag < ActiveRecord::Base

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :offer
  belongs_to :group

  has_many :offers, :through => :curriculum_unit

  has_many :allocations
  has_many :lessons
  has_many :discussions
  has_many :schedule_events
  has_many :assignments
  has_many :users, :through => :allocations, :uniq => true
  has_many :groups, :finder_sql => Proc.new {
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
        courses_related(Course.find(at['course_id']), down = true)
    end

    [self.id, atgs].flatten.compact.uniq.sort
  end

  def unallocate_user_in_related(user_id)
    Allocation.destroy_all(user_id: user_id, allocation_tag_id: self.related)
  end

  def is_user_allocated_in_related?(user_id)
    not Allocation.
      select(:allocation_tag_id).
      where(
        :user_id => user_id,
        :allocation_tag_id => self.related
    ).uniq.empty?
  end

  def is_only_user_allocated_in_related?(user_id)
    Allocation.
      select(:allocation_tag_id).
      where("user_id != ?", user_id).
      where(:allocation_tag_id => self.related
    ).uniq.empty?
  end

  def self.user_allocation_tag_related_with_class(class_id, user_id)
    related_allocations = AllocationTag.find_related_ids(Group.find(class_id).allocation_tag.id) #allocations relacionadas à turma
    allocation = Allocation.first(:conditions => ["allocation_tag_id IN (?) AND user_id = #{user_id}", related_allocations])
    return (allocation.nil? ? nil : allocation.allocation_tag)
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
