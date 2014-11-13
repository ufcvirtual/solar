object @group

attributes :id, :code, :offer_id

glue @group.offer do
  attributes :start_date, :end_date, :course_id, :curriculum_unit_id
end

node :students do |group|
  group.students_participants.count
end
