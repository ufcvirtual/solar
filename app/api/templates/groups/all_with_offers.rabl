collection @offers

child :course do
  attributes :id, :code, :name
end

child :curriculum_unit do
  attributes :id, :name, :code, :working_hours
  node(:curriculum_unit_type) { |uc| uc.curriculum_unit_type.description }
end

child :semester do
  attributes :name
end

node(:start_date) { |offer| offer.start_date }
node(:end_date) { |offer| offer.end_date }

child :groups do
  attributes :code, :status, :name, :location, :integrated
end

