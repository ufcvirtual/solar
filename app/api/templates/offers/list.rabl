collection @offers

child :course do
  attributes :id, :code, :name, :min_grade_to_final_exam, :min_hours, :min_final_exam_grade, :final_exam_passing_grade, :passing_grade
end

child :curriculum_unit do
  attributes :id, :code, :name, :resume, :objectives, :syllabus, :prerequisites, :credits, :working_hours, :min_hours
end

child :semester do
  attributes :name
end

attributes :created_at, :updated_at

node(:start_date) { |offer| offer.start_date }
node(:end_date) { |offer| offer.end_date }