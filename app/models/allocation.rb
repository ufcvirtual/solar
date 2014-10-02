class Allocation < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :profile
  belongs_to :updated_by, class_name: "User", foreign_key: :updated_by_user_id

  has_one :course,               through: :allocation_tag, conditions: ["course_id is not null"]
  has_one :curriculum_unit,      through: :allocation_tag, conditions: ["curriculum_unit_id is not null"]
  has_one :offer,                through: :allocation_tag, conditions: ["offer_id is not null"]
  has_one :group,                through: :allocation_tag, conditions: ["group_id is not null"]
  has_one :curriculum_unit_type, through: :allocation_tag, conditions: ["curriculum_unit_type_id is not null"]

  has_many :chat_rooms
  has_many :chat_messages
  has_many :chat_participants

  validates :profile_id, :user_id, presence: true
  validate :valid_profile_in_allocation_tag?

  validates_uniqueness_of :profile_id, scope: [:user_id, :allocation_tag_id]

  def can_change_group?
    not [Allocation_Cancelled, Allocation_Rejected].include?(status)
  end

  def pending?
    status == Allocation_Pending # problema na delecao reativada
  end

  def pending!
    update_attributes(status: Allocation_Pending)
  end

  def activate!
    update_attributes(status: Allocation_Activated)
  end

  def reject!
    update_attributes(status: Allocation_Rejected)
  end

  def deactivate!
    update_attributes(status: Allocation_Cancelled)
  end

  def request_reactivate!
    ## verifica se oferta ou turma estao dentro do prazo
    ## se nao for na oferta ou na turma? precisa verificar???
    # - if group.offer.is_active? (verificar se funciona)

    al_offer = offer || group.offer
    update_attributes(status: Allocation_Pending_Reactivate) if al_offer.enrollment_period.include?(Date.today)
  end

  def cancel!
    pending? ? destroy : deactivate!
  end

  def groups
    allocation_tag.groups unless allocation_tag.nil?
  end

  def user_name
    user.name
  end

  def refer_to
    allocation_tag.refer_to
  end

  def curriculum_unit_related # uc, offer, group
    return curriculum_unit if refer_to == 'curriculum_unit'
    send(refer_to).curriculum_unit rescue nil
  end

  def course_related # course, offer, group
    return course if refer_to == 'course'
    send(refer_to).course rescue nil
  end

  def semester_related # offer, group
    send(refer_to).semester rescue nil
  end

  def offers_related # uc, course, offer, group
    case refer_to
    when 'curriculum_unit', 'course'
      send(refer_to).offers
    when 'offer'
      [offer]
    when 'group'
      [group.offer]
    end
  end

  def status_color
    case status
      when Allocation_Pending_Reactivate, Allocation_Pending; "#FF6600"
      when Allocation_Activated; "#006600"
      when Allocation_Cancelled, Allocation_Rejected; "#FF0000"
    end
  end

  def change_to_new_status(type, current_user)
    self.updated_by_user_id = current_user.id
    case type
      when :activate
        activate!
      when :deactivate
        deactivate!
      when :request_reactivate

        raise CanCan::AccessDenied if user_id != current_user.id
        request_reactivate!

      when :cancel, :cancel_request, :cancel_profile_request

        # apenas quem pede matricula/perfil pode cancelar pedido / perfil de aluno e basico nao pode ser cancelado pela lista de perfis
        raise CanCan::AccessDenied if user_id != current_user.id or
          (type == :cancel_profile_request and (profile_id == Profile.student_profile or profile.has_type?(Profile_Type_Basic)))
        cancel!

      when :reject
        reject!
      when :accept
        activate!
      when :pending
        pending!
    end # case
    errors.empty?
  end


  ## class methods


  def self.enrollments(args = {})
    joins(allocation_tag: {group: :offer}, user: {}).where(query_for_enrollments(args), args).order("users.name")
  end

  def self.pending
    joins(:profile)
      .where("allocations.status IN (?, ?) AND NOT cast(profiles.types & ? as boolean)", Allocation_Pending, Allocation_Pending_Reactivate, Profile_Type_Student)
      .order("allocations.id")
  end

  def self.remove_unrelated_allocations(user, allocations)
    # recovers only responsible profiles allocations and remove all allocatios which user has no relation with
    allocations.where("cast(profiles.types & ? as boolean)", Profile_Type_Class_Responsible).select { |a| user.can?(:manage_profiles, Allocation, on: [a.allocation_tag_id]) }
  end

  def self.responsibles(allocation_tags_ids)
    includes(:profile, :user)
      .where("allocation_tag_id IN (?) AND allocations.status = ? AND (cast(profiles.types & ? as boolean))", allocation_tags_ids, Allocation_Activated, Profile_Type_Class_Responsible)
      .order("users.name")
  end

  def self.list_for_designates(allocation_tags_ids, is_admin = false)
    query = ["allocation_tag_id IN (?)"]
    query << (!!is_admin ? "not(profiles.types & #{Profile_Type_Basic})::boolean" : "(profiles.types & #{Profile_Type_Class_Responsible})::boolean")

    joins(:profile, :user).where(query.join(' AND '), allocation_tags_ids).order("users.name, profiles.name")
  end

  private

    def self.query_for_enrollments(args = {})
      query = ["profile_id = #{Profile.student_profile}", "allocation_tags.group_id IS NOT NULL"]

      if args.any?
        query << "groups.offer_id = :offer_id" if args[:offer_id].present?
        query << "groups.id IN (:group_id)" if args[:group_id].present?
        query << "allocations.status = :status" if args[:status].present?

        if args[:user_search].present?
          user_search = [args[:user_search].split(" ").compact.join(":*&"), ":*"].join
          query << "to_tsvector('simple', unaccent(users.name)) @@ to_tsquery('simple', unaccent('#{user_search}'))"
        end
      end
      query.join(' AND ')
    end

    def valid_profile_in_allocation_tag?
      errors.add(:profile_id, I18n.t("allocations.error.student_in_group")) if profile_id == Profile.student_profile and allocation_tag.refer_to != 'group'
    end

end
