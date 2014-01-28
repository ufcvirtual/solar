collection @groups

@groups.each do |group|
  extends 'groups/show', locals: {group: group}
end 
