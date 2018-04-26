require 'active_support/concern'

module Taggable
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_empty_modules, if: Proc.new { |ac| ac.respond_to?(:lesson_modules) }

    after_create :allocation_tag_association
    after_create :allocate_profiles

    has_one :allocation_tag, dependent: :destroy

    has_many :allocations, through: :allocation_tag
    has_many :users,       through: :allocation_tag

    before_destroy :can_destroy?

    attr_accessor :user_id
  end

  def destroy_empty_modules
    lesson_modules.map(&:delete_with_academic_allocations) if lesson_modules.map(&:lessons).flatten.empty?
  end

  def can_destroy?
    errors.add(:base, I18n.t(:dont_destroy_with_lower_associations)) if any_lower_association?
    errors.add(:base, I18n.t(:dont_destroy_with_many_allocations))   if allocations.where(status: Allocation_Activated).select("DISTINCT user_id").count > 1 # se possuir mais de um usuario ativo alocado, nao deleta
    # pode destruir somente se o conteudo for apenas um modulo de aula
    errors.add(:base, I18n.t(:dont_destroy_with_content))            unless (academic_allocations.count == 0 || (academic_allocations.count == 1 && academic_allocations.where(academic_tool_type: 'LessonModule').any?))
    raise false if errors.any?
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
  def allocate_user(user_id, profile_id, updated_by_user_id=nil)
    allocation = Allocation.where(user_id: user_id, allocation_tag_id: self.allocation_tag.id, profile_id: profile_id).first_or_initialize
    allocation.status = Allocation_Activated
    allocation.updated_by_user_id = updated_by_user_id # if nil, was updated by system
    allocation.save!
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
      al.update_attributes(status: Allocation_Cancelled, updated_by_user_id: updated_by_user_id)
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
      al.update_attributes(status: new_status, updated_by_user_id: updated_by_user_id)
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
      .where("cast(types & ? as boolean)", profile_type).distinct
  end

  def users_with_profile(profile_id = nil, related = true)
    query = {}
    query.merge!({profile_id: profile_id}) unless profile_id.nil?

    User.joins(:allocations).where("allocations.allocation_tag_id IN (?)", (related ? self.allocation_tag.related({upper:true}) : self.allocation_tag.id) )
      .where(query).distinct
  end

  def related(options={upper: true, lower: true, name: nil})
    RelatedTaggable.related(self, options)
  end

  def update_digital_class(ignore_changes=false)
    DigitalClass.update_taggable(self, ignore_changes) unless saved_change_to_created_at?
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

end
