collection @offers

child :course do
  attributes :id, :code, :name
end

child :curriculum_unit do
  attributes :id, :code, :name
end

child :semester do
  attributes :name
end

attributes :created_at, :updated_at

node(:start_date) { |offer| offer.start_date }
node(:end_date) { |offer| offer.end_date }
