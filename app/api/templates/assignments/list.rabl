collection @assignments

attributes :id, :name, :enunciation, :start_hour, :end_hour, :controlled

@assignments.each do |assignment|
  node(:type_assignment) { assignment.type_assignment == 0 ? :individual : :group}
end