collection @objects

if @assignment.type_assignment.to_i == Assignment_Type_Individual
	@objects.each do |participant|
		@acu = @assignment.acu_by_user(participant.id)
	  extends 'assignments/participants', locals: {participant: participant}
	end
else
	@objects.each do |group|
	  extends 'assignments/groups', locals: {group: group}
	end
end
