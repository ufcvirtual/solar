collection @students, :root => :students, :object_root => :student

@students.each do |student|
  extends 'groups/student_info', locals: { student: student }
end
