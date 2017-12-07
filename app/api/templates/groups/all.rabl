object @offers

@offers.each do |of|
	of.status = @group_status
end	

child :course do
  attributes :code, :name
end

child :curriculum_unit do
  attributes :name, :code, :resume, :syllabus, :credits, :working_hours
  node(:curriculum_unit_type) { |uc| uc.curriculum_unit_type.description }
end

child get_groups: :groups do 
  attributes :code, :status
  node(:count_students) { |g| g.students_participants.count }
end


