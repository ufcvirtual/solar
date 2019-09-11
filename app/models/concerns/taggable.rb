require 'active_support/concern'

module Taggable
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_empty_modules, if: Proc.new { |ac| ac.respond_to?(:lesson_modules) }
    before_destroy :can_destroy?

    after_create :allocation_tag_association
    after_create :allocate_profiles

    has_one :allocation_tag, dependent: :destroy

    has_many :allocations, through: :allocation_tag
    has_many :users,       through: :allocation_tag


    attr_accessor :user_id, :api
  end

  def destroy_empty_modules
    lesson_modules.map(&:delete_with_academic_allocations) if lesson_modules.map(&:lessons).flatten.empty?
  end

  def can_destroy?
    errors.add(:base, I18n.t(:dont_destroy_with_lower_associations)) if any_lower_association?
    all = allocations.where(status: Allocation_Activated)
    if api.nil?
      errors.add(:base, I18n.t(:dont_destroy_with_many_allocations))  if all.select('DISTINCT user_id').count > 1 || all.where(profile_id: 1).any? # se possuir mais de um usuario ativo alocado ou pelo menos 1 aluno ativo, nao deleta
    else
      errors.add(:base, I18n.t(:dont_destroy_with_many_allocations))  if all.select('DISTINCT user_id').count > 0
    end
    # pode destruir somente se o conteudo for apenas um modulo de aula
    errors.add(:base, I18n.t(:dont_destroy_with_content)) unless (academic_allocations.count == 0 || (academic_allocations.count == 1 && academic_allocations.where(academic_tool_type: 'LessonModule').any?))
    # raise false
    return false if errors.any?
    errors.empty?
  end

  def allocation_tag_association
    AllocationTag.create({self.class.name.underscore.to_sym => self})
  end

  ## criacao de lesson module default :: devera ser chamada apenas por groups e offers
  def create_default_lesson_module(name)
    LessonModule.transaction do
      lm = LessonModule.create(name: name, is_default: true)
      lm.academic_allocations.create(allocation_tag_id: allocation_tag.id)
    end if respond_to?(:lesson_modules)
  end

  ## Alocações

  # creates or activates user allocation
  def allocate_user(user_id, profile_id, updated_by_user_id=nil, origin_group_id=nil, status=Allocation_Activated, notify=false)
    allocation = Allocation.where(user_id: user_id, allocation_tag_id: self.allocation_tag.id, profile_id: profile_id).first_or_initialize
    new_record, old_status = allocation.new_record?, allocation.status
    allocation.status = status
    allocation.updated_by_user_id = updated_by_user_id # if nil, was updated by system

    # if was merged and not anymore, but student still allocated at last group
    allocation.origin_group.cancel_allocations(user_id, profile_id) unless allocation.origin_group_id.blank? || origin_group_id == allocation.origin_group_id
    unless origin_group_id.blank?
      Allocation.where(origin_group_id: origin_group_id, user_id: user_id, profile_id: profile_id).where("id != ?", allocation.id).each do |al|
        al.group.change_allocation_status(user_id, Allocation_Cancelled, nil, {profile_id: profile_id})
      end
    end

    allocation.origin_group_id = (origin_group_id.blank? ? nil : origin_group_id)
    allocation.save!

    allocation.user.notify_by_email(nil, nil, false, [], allocation.allocation_tag) if notify && status == Allocation_Activated && (new_record || old_status != Allocation_Activated) && profile_id == Profile.student_profile && (!allocation.group.blank? && allocation.group.status)

    allocation
  end

  def cancel_allocations(user_id = nil, profile_id = nil, updated_by_user_id=nil, opts = {}, raise_error = false)
    query = {}
    query.merge!({user_id: user_id})       unless user_id.nil?
    query.merge!({profile_id: profile_id}) unless profile_id.nil?

    all = if opts.include?(:related) && opts[:related]
      Allocation.where(allocation_tag_id: allocation_tag.related({lower: true}))
    else
      allocations
    end

    all_query = all.where(query)

    if raise_error && all_query.empty?
      Rails.logger.info "[API] [ERROR] [#{Time.now}] can't cancel allocation that doesn't exists user_id #{user_id} - profile_id #{profile_id} - allocation_tag_id #{allocation_tag.id}"
      raise "allocation doesnt exist"
    end

    all_query.each do |al|
      al.update_attributes(status: Allocation_Cancelled, updated_by_user_id: updated_by_user_id, origin_group_id: nil)
    end
  end

  def change_allocation_status(user_id, new_status, updated_by_user_id=nil, opts = {}) # opts = {profile_id, related}
    where = {user_id: user_id}
    where.merge!({profile_id: opts[:profile_id]}) if opts.include?(:profile_id) && !opts[:profile_id].nil?

    all = if opts.include?(:related) && opts[:related]
      Allocation.where(allocation_tag_id: allocation_tag.related({lower: true})).where(where)
    else
      allocations.where(where)
    end
    all.each do |al|
      # if was merged and not anymore, but student cancel allocation at last group
      al.origin_group.cancel_allocations(user_id, opts[:profile_id]) unless al.origin_group_id.blank? || opts[:origin_group_id] == al.origin_group_id || opts[:profile_id].blank?

      al.update_attributes(status: new_status, updated_by_user_id: updated_by_user_id, origin_group_id: (opts[:origin_group_id].blank? ? nil : opts[:origin_group_id]))
    end

    origin_group = Group.where(id: opts[:origin_group_id]).first

    # in case of allocations dont exists, system must creat them to cancel
    unless opts[:create_if_dont_exists].blank? || (all.any? && origin_group.blank?) || opts[:profile_id].blank?
      new_allocation = Allocation.create allocation_tag_id: allocation_tag.id, user_id: user_id, profile_id: opts[:profile_id], status: new_status, origin_group_id: (opts[:origin_group_id].blank? ? nil : opts[:origin_group_id]) if all.blank?

      unless (origin_group.blank? && new_allocation.try(:origin_group).blank?)
        new_al = Allocation.where(allocation_tag_id: (new_allocation.blank? ? origin_group : new_allocation.origin_group).try(:allocation_tag).try(:id), user_id: user_id, profile_id: opts[:profile_id]).first_or_initialize
        new_al.status = Allocation_Merged
        new_al.save
      end
    end
  end

  ## desabilitar todas as alocacoes do usuario nesta ferramenta academica
  def disable_user_allocations(user_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Cancelled, updated_by_user_id)
  end

  ## desabilitar todas as alocacoes do usuario para o perfil informado nesta ferramenta academica
  def disable_user_profile_allocation(user_id, profile_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Cancelled, updated_by_user_id, {profile_id: profile_id})
  end

  ## desabilitar todas as alocacoes do usuario nesta ferramenta academica e nas ferramentas academicas abaixo desta (ex: offers -> groups)
  def disable_user_allocations_in_related(user_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Cancelled, updated_by_user_id, {related: true})
  end

  ## desabilitar todas as alocacoes do usuario para o perfil informado nesta ferramenta academica e nas ferramentas academicas abaixo desta (ex: offers -> groups)
  def disable_user_profile_allocations_in_related(user_id, profile_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Cancelled, updated_by_user_id, {profile_id: profile_id, related: true})
  end

  ## ativar alocacao do usuario nesta ferramenta academica
  def enable_user_allocations(user_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Activated, updated_by_user_id)
  end

  ## ativar alocacao do usuario nesta ferramenta academica e nas ferramentas academicas abaixo desta (ex: offers -> groups)
  def enable_user_allocations_in_related(user_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Activated, updated_by_user_id, {related: true})
  end

  ## ativar alocacao do usuario para o perfil informado nesta ferramenta academica
  def enable_user_profile_allocation(user_id, profile_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Activated, updated_by_user_id, {profile_id: profile_id})
  end

  ## ativar alocacao do usuario para o perfil informado nesta ferramenta academica e nas ferramentas academicas abaixo desta (ex: offers -> groups)
  def enable_user_profile_allocations_in_related(user_id, profile_id, updated_by_user_id=nil)
    change_allocation_status(user_id, Allocation_Activated, updated_by_user_id, {profile_id: profile_id, related: true})
  end

  ########

  def info(args = {})
    params = {separator: '-', include_type: false}.merge(args)
    except = params[:include_type] ? nil : [:curriculum_unit_type_id, :curriculum_unit_type]

    detailed_info.except(*except).values.uniq.join " #{params[:separator]} "
  end

  ## Após criar algum elemento taggable (uc, curso, turma, oferta), verifica todos os perfis que o usuário possui
  ## e, para cada um daqueles que possuem permissão de realizar a ação previamente realizada, é criada uma alocação
  def allocate_profiles
    return unless user_id

    controller_name = self.class.name.underscore << 's'
    profiles_with_access = User.find(user_id).profiles.joins(:resources).where(resources: {action: 'create', controller: controller_name}).pluck(:id)

    profiles_with_access.each do |profile|
      allocate_user(user_id, profile)
    end
  end

  def users_with_profile_type(profile_type, related = true)
    User.joins(allocations: :profile).where("allocations.allocation_tag_id IN (?)", (related ? self.allocation_tag.related({ upper:true }) : self.allocation_tag.id) )
      .where("cast(types & ? as boolean)", profile_type).uniq
  end

  def users_with_profile(profile_id = nil, related = true)
    query = {}
    query.merge!(allocations: {profile_id: profile_id}) unless profile_id.nil?

    User.joins(:allocations).where("allocations.allocation_tag_id IN (?)", (related ? self.allocation_tag.related({upper:true}) : self.allocation_tag.id) )
      .where(query).uniq
  end

  def related(options={upper: true, lower: true, name: nil})
    RelatedTaggable.related(self, options)
  end

  def update_digital_class(ignore_changes=false)
    DigitalClass.update_taggable(self, ignore_changes) unless created_at_changed?
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

end
