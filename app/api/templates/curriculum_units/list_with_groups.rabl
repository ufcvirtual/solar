collection @curriculum_units

extends "curriculum_units/list"

node :groups do |uc|
  uc.groups.where(id: @u_groups).map { |group|
    {
      id: group.id,
      code: group.code,
      semester: group.offer.semester.name
    }
  }
end
