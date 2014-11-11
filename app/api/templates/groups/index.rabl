collection @groups

@groups.each do |group|
  extends 'groups/group', locals: {group: group}
end
