class Offer < ActiveRecord::Base

  include Taggable

  belongs_to :course
  belongs_to :curriculum_unit

  has_one :enrollment

  has_many :groups
  has_many :assignments, :through => :allocation_tag

  validates :course, :presence => true
  validates :curriculum_unit, :presence => true
  validates :semester, :presence => true, :format => {:with => %r{^(\d{4}).(\d{1}*[1-2])} } # formato: 9999.1/.2
  validates :start, :presence => true
  validates :end, :presence => true
  
  validate :semester_must_be_unique

  def has_any_lower_association?
      self.groups.count > 0
  end

  def lower_associated_objects
    groups
  end

  ##
  # Para um mesmo curso e uma mesma unidade curricular, o semestre deve ser único
  ##
  def semester_must_be_unique
    offers_with_same_semester = Offer.find_all_by_curriculum_unit_id_and_course_id_and_semester(curriculum_unit_id, course_id, semester)
    errors.add(:semester, I18n.t(:existing_semester, :scope => [:offers])) if (@new_record == true or semester_changed?) and offers_with_same_semester.size > 0
  end

end
