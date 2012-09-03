module Taggable

  def self.included(base)   
    base.before_destroy :check_associations
    base.after_create :allocation_tag_association
    base.after_create :user_editor_allocation

    base.has_one :allocation_tag, :dependent => :destroy
    base.has_many :allocations, :through => :allocation_tag
    base.has_many :users, :through => :allocation_tag
  end

  def check_associations
    if has_associations?
      return false
    end
    unallocate_if_up_to_one_user
  end

  def has_associations?
    self.allocation_tag.related.count > 1
  end

  def unallocate_if_up_to_one_user
    if is_up_to_one_user_allocated?
      @user_id = self.allocations.select(:user_id).first.user_id if self.allocations.count > 0
      unallocate_user(user_id) if user_id
      return true
    end
    return false
  end

  def is_up_to_one_user_allocated?
    not (self.allocations.select("DISTINCT user_id").count  > 1)
  end

  def unallocate_user(user_id)
    self.allocation_tag.unallocate_user_in_related(user_id)
  end

  def allocation_tag_association
    AllocationTag.create({self.class.name.underscore.to_sym => self})
  end

  def user_editor_allocation
    allocate_user(user_id, Curriculum_Unit_Initial_Profile) if user_id
  end

  def allocate_user(user_id, profile_id)
    allocation_tag.allocate_user(user_id, profile_id)
  end

  def is_only_user_allocated?(user_id)
    self.allocation_tag.is_only_user_allocated_in_related?(user_id)
  end

  def can_destroy?
    ((is_up_to_one_user?) and (no_associations?))
  end
end