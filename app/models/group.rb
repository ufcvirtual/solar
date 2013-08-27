class Group < ActiveRecord::Base

  include Taggable

  belongs_to :offer

  has_one :curriculum_unit, :through => :offer
  has_one :course, :through => :offer

  has_many :assignments, through: :allocation_tag

  validates :offer_id, :presence => true
  validates :code, :presence => true

  # modulo default da turma
  after_create :set_default_lesson_module

  def code_semester
    "#{code} - #{offer.semester.name}"
  end

  def self.find_all_by_curriculum_unit_id_and_user_id(curriculum_unit_id, user_id)
    Group.joins(offer: [:semester]).where(
      offers: {curriculum_unit_id: curriculum_unit_id}, 
      groups: {id: User.find(user_id).groups}).order('semesters.name DESC, groups.code ASC')
  end

  def has_any_lower_association?
    false
  end

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_group, scope: :lesson_modules))
  end

  # Recupera os participantes com perfil de estudante
  def students_participants
    allocations.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean)").where(status: Allocation_Activated)
    # allocations.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean)").where(status: Allocation_Activated).map { |allocation|
    #   { id: allocation.id, user_name: allocation.user.name, user_id: allocation.user_id }
    # }
    # allocations = self.allocations.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean)").where(status: Allocation_Activated)
    # allocations.collect{ |allocation| {allocation_id: allocation.id, user_id: allocation.user_id, user_name: allocation.user.name} }
  end

end
