class Course < ActiveRecord::Base
  include Taggable

  has_many :offers
  has_many :groups,                -> { uniq }, through: :offers
  has_many :curriculum_units,      -> { uniq }, through: :offers
  has_many :curriculum_unit_types, -> { uniq }, through: :curriculum_units
  has_many :academic_allocations,  through: :allocation_tag

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: { case_sensitive: false }, if: -> {edx_course.nil?}
  validate :unique_name, unless: -> {edx_course.nil? or courses_names.nil?}
  validates :min_hours, numericality: { greater_than_or_equal_to: 0, allow_blank: true, less_than_or_equal_to: 100 }
  validates_length_of :code, maximum: 40
  validates :passing_grade, :min_grade_to_final_exam, :min_final_exam_grade, :final_exam_passing_grade, numericality: { greater_than_or_equal_to: 0, allow_blank: true, less_than_or_equal_to: 10 }
  validate :smaller_than_passing_grade, if: -> {!passing_grade.blank? && !min_grade_to_final_exam.blank?}
  validates :passing_grade, presence: true, if: -> {passing_grade.blank? && (!min_grade_to_final_exam.blank? || !min_final_exam_grade.blank? || !final_exam_passing_grade.blank?)}

  after_save :update_digital_class, if: -> {saved_change_to_code? || saved_change_to_name?}
  before_update :update_correspondent_uc, if: -> {!ignore_uc}
  after_destroy :destroy_correspondent_uc, if: -> {!ignore_uc}

  attr_accessor :edx_course, :courses_names, :ignore_uc

  def any_lower_association?
    offers.count > 0
  end

  def smaller_than_passing_grade
    errors.add(:min_grade_to_final_exam, I18n.t('courses.error.passing_grade')) if passing_grade <= min_grade_to_final_exam
  end

  def lower_associated_objects
    offers
  end

  def code_name
    [code, name].join(' - ')
  end

  def detailed_info
    { course: name }
  end

  def unique_name
    if courses_names.include?(name)
      errors.add(:name, I18n.t('edx.errors.existing_name'))
    else
      codes = courses_names.collect { |name| name.slice(0..2).upcase }
      errors.add(:name, I18n.t('edx.errors.existing_code')) if codes.include?(name.slice(0..2).upcase)
    end
  end

  def self.all_associated_with_curriculum_unit_by_name(type = 3)
    Course.where(name: CurriculumUnit.where(curriculum_unit_type_id: type).pluck(:name))
  end

  private


    def update_correspondent_uc
      # changes => {key: [before, after]}
      return unless self.valid? && changes.any? && (changes.has_key?(:name) || changes.has_key?(:code))

      before_name = changes[:name].nil? ? name : changes[:name].first
      before_code = changes[:code].nil? ? code : changes[:code].first

      curriculum_unit = CurriculumUnit.find_by_name_and_code(before_name, before_code)
      unless curriculum_unit.blank?
        curriculum_unit.ignore_course = true
        if curriculum_unit && !curriculum_unit.update_attributes(code: code, name: name)
          errors.messages.merge!(curriculum_unit.errors.messages)
          return false
        end
      end

      true
    end

    def destroy_correspondent_uc
      curriculum_unit = CurriculumUnit.find_by_name_and_code(name, code)
      unless curriculum_unit.blank?
        curriculum_unit.ignore_course = true
        curriculum_unit.destroy
      end
    end
end
