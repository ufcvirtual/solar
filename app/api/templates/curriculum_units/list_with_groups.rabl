collection @curriculum_units

extends "curriculum_units/list"

child :groups do |groups|
  groups.each do |group|
    extends 'groups/show', locals: {group: group}
  end
end