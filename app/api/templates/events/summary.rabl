collection @objects

@objects.each do |participant|
  @acu = @event.acu_by_user(participant.id)
  extends 'events/participants', locals: {participant: participant}
end
