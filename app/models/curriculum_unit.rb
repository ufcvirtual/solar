class CurriculumUnit < ActiveRecord::Base
  include Taggable

  belongs_to :curriculum_unit_type

  has_many :offers
  has_many :groups,               through: :offers, uniq: true
  has_many :courses,              through: :offers, uniq: true
  has_many :academic_allocations, through: :allocation_tag

  before_create  :create_correspondent_course,  if: 'curriculum_unit_type_id == 3'
  before_update :update_correspondent_course,   if: 'curriculum_unit_type_id == 3 && !ignore_course'
  after_destroy :destroy_correspondent_course,  if: 'curriculum_unit_type_id == 3 && !ignore_course'

  validates :code, uniqueness: true, length: { maximum: 40 }, allow_blank: false
  validates :name, length: { maximum: 120 }
  validates :name, :curriculum_unit_type, :resume, :syllabus, :objectives, :code, presence: true
  validates :passing_grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true}
  validates :working_hours, numericality: { greater_than: 0, allow_blank: true}

  after_save :update_digital_class, if: "code_changed? || name_changed?"

  attr_accessor :ignore_course

  def any_lower_association?
    offers.count > 0
  end

  def lower_associated_objects
    offers
  end

  def code_name
    [code, name].reject(&:blank?).join ' - '
  end

  def detailed_info
    {
      curriculum_unit_type: curriculum_unit_type.description,
      curriculum_unit: name
    }
  end

  def course
    Course.find_by_name_and_code(name, code) if curriculum_unit_type_id == 3
  end

  ## Todas as UCs do usuario, atraves das allocations
  def self.all_by_user(user)
    al              = user.allocations.where(status: Allocation_Activated)
    my_direct_uc    = al.map(&:curriculum_unit)
    ucs_by_offers   = al.map(&:offer).compact.map(&:curriculum_unit).uniq
    ucs_by_courses  = al.map(&:course).compact.map(&:curriculum_units).uniq
    ucs_by_groups   = al.map(&:group).compact.map(&:curriculum_unit).uniq

    return [my_direct_uc + ucs_by_offers + ucs_by_courses + ucs_by_groups].flatten.compact.uniq.sort
  end

  def verify_evaluative_tools
    acs = AcademicAllocation.where(allocation_tag_id: allocation_tag.related, frequency: true).where('final_exam IS NULL AND equivalent_academic_allocation_id IS NULL').pluck(:max_working_hours)
    (acs.empty? ? false : acs.sum(:max_working_hours) == working_hours)
  end

  ## triggers

  trigger.after(:update).of(:curriculum_unit_type_id) do
    <<-SQL
      -- update as linhas onde o curriculum unit esta para mudar o tipo
      UPDATE related_taggables
         SET curriculum_unit_type_id = NEW.curriculum_unit_type_id,
             curriculum_unit_type_at_id = (SELECT id FROM allocation_tags WHERE curriculum_unit_type_id = NEW.curriculum_unit_type_id)
       WHERE curriculum_unit_id = OLD.id;
    SQL
  end

  private

    ## para curso livre, é criado um curso com o mesmo nome e codigo da UC
    def create_correspondent_course
      course = Course.new code: code, name: name
      course.user_id = user_id
      course.save
      errors.messages.merge!(course.errors.messages) unless course.save
      false if errors.any?
    end

    def update_correspondent_course
      # changes => {key: [before, after]}
      return unless self.valid? && changes.any? && (changes.has_key?(:name) || changes.has_key?(:code))

      before_name = changes[:name].nil? ? name : changes[:name].first
      before_code = changes[:code].nil? ? code : changes[:code].first

      course = Course.find_by_name_and_code(before_name, before_code)
      course.ignore_uc = true
      if course && !course.update_attributes(code: code, name: name)
        errors.messages.merge!(course.errors.messages)
        return false
      end

      true
    end

    def destroy_correspondent_course
      course.ignore_uc = true
      course.destroy
    end

end
