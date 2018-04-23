class AutomaticStudentStatus < ActiveRecord::Migration[5.0]
  def up
    add_column :courses, :min_grade_to_final_exam, :float
    add_column :courses, :min_hours, :integer
    add_column :courses, :min_final_exam_grade, :float
    add_column :courses, :final_exam_passing_grade, :float
    add_column :courses, :passing_grade, :float

    offers = Offer.joins(:curriculum_unit).where('curriculum_units.passing_grade IS NOT NULL')
    offers.each do |offer|
      course = offer.course
      unless course.nil?
        course.passing_grade = offer.try(:curriculum_unit).try(:passing_grade)
        course.save
      end
    end

    remove_column :curriculum_units, :passing_grade

    add_column :allocations, :grade_situation, :integer
    add_column :allocations, :parcial_grade, :float
    add_column :allocations, :final_exam_grade, :float

  add_column :allocation_tags, :setted_situation, :boolean, default: false
  add_column :allocation_tags, :situation_date, :date
  end

  def down
    remove_column :courses, :min_grade_to_final_exam
    remove_column :courses, :min_hours
    remove_column :courses, :min_final_exam_grade
    remove_column :courses, :final_exam_passing_grade
    add_column :curriculum_units, :passing_grade, :float

    offers = Offer.joins(:course).where('courses.passing_grade IS NOT NULL')
    offers.each do |offer|
      uc = offer.curriculum_unit
      uc.passing_grade = offer.course.passing_grade
      uc.save
    end

    remove_column :courses, :passing_grade

    remove_column :allocations, :grade_situation
    remove_column :allocations, :parcial_grade
    remove_column :allocations, :final_exam_grade

    remove_column :allocation_tags, :setted_situation
    remove_column :allocation_tags, :situation_date
  end
end
