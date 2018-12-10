collection @offers

child :course do
  attributes :id, :code, :name
end

child :curriculum_unit do
  attributes :id, :name, :code, :resume, :syllabus, :credits, :working_hours
  node(:curriculum_unit_type) { |uc| uc.curriculum_unit_type.description }
end

child :semester do
  attributes :name
end

child @groups do
  attributes :id, :code, :status, :name
  node :students do |g|
    students = g.students_participants
    {count: students.count, names: (students.map(&:name) rescue [])}
  end
end
