module Taggable

  def self.included(base)   
    base.before_destroy :unallocate_if_possible
    base.after_create :allocation_tag_association
    base.after_create :allocate_profiles

    base.has_one :allocation_tag, :dependent => :destroy
    base.has_many :allocations, :through => :allocation_tag
    base.has_many :users, :through => :allocation_tag
    base.has_many :lesson_modules, :through => :allocation_tag

    attr_accessor :user_id
  end

  def unallocate_if_possible
    return false if self.has_any_lower_association?
    unallocate_if_up_to_one_user
  end

  def unallocate_if_up_to_one_user
    if at_most_one_user_allocated?
      @user_id = self.allocations.select(:user_id).first.user_id if self.allocations.count > 0
      unallocate_user_in_lower_associations(user_id) if user_id
      return true
    end
    return false
  end

  def at_most_one_user_allocated?
    not (self.allocations.select("DISTINCT user_id").count  > 1)
  end

  def unallocate_user(user_id)
    Allocation.destroy_all(user_id: user_id, allocation_tag_id: self.allocation_tag.id)
  end

  def unallocate_user_in_related(user_id)
    self.allocation_tag.unallocate_user_in_related(user_id)
  end

  def allocation_tag_association
    AllocationTag.create({self.class.name.underscore.to_sym => self})
  end

  def allocate_user(user_id, profile_id)
    Allocation.create(:user_id => user_id, :allocation_tag_id => self.allocation_tag.id, :profile_id => profile_id, :status => Allocation_Activated)
  end

  def is_only_user_allocated?(user_id)
    self.allocation_tag.is_only_user_allocated_in_related?(user_id)
  end

  def can_destroy?
    ((is_up_to_one_user?) and (not has_any_lower_association?))
  end

  ## criacao de lesson module default :: devera ser chamada apenas por groups e offers
  def create_default_lesson_module(name)
    LessonModule.create(allocation_tag: allocation_tag, name: name, is_default: true)
  end

  ##
  # Após criar algum elemento taggable (uc, curso, turma, oferta), verifica todos os perfis que o usuário possui 
  # e, para cada um daqueles que possuem permissão de realizar a ação previamente realizada, é criada uma alocação
  ##
  def allocate_profiles
    if user_id
      profiles_with_access = User.find(user_id).profiles.joins(:resources).where(resources: {action: 'create', controller: self.class.name.underscore << 's'}).flatten

      profiles_with_access.each do |profile|
        allocate_user(user_id, profile.id)
      end
    end
  end

  private
    def unallocate_user_in_lower_associations(user_id)    
      self.lower_associated_objects do |down_associated_object| 
        down_associated_object.unallocate_user_in_lower_associations(user_id)
      end if self.respond_to?(:lower_associated_objects)
      unallocate_user(user_id)
    end

end