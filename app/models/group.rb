class Group < ActiveRecord::Base

  include Taggable

  belongs_to :offer

  has_one :curriculum_unit, :through => :offer
  has_one :course, :through => :offer

  has_many :assignments, :through => :allocation_tag

  validates :offer_id, :presence => true
  validates :code, :presence => true

  # modulo default da turma
  after_create :set_default_lesson_module

  def code_semester
    "#{code} - #{offer.semester}"
  end

  def self.find_all_by_curriculum_unit_id_and_user_id(curriculum_unit_id, user_id)
    Group.joins(:offer).where(
      offers: {curriculum_unit_id: curriculum_unit_id}, 
      groups: {id: User.find(user_id).groups}).order('offers.semester DESC, groups.code ASC')
  end

  def has_any_lower_association?
    false
  end

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_group, scope: :lesson_modules))
  end

end
