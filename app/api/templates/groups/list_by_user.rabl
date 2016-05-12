collection @groups

@groups.each do |group|
  extends 'groups/show_group', locals: { group: group }
end
