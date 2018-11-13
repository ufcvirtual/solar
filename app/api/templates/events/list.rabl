collection @events
attributes :id, :title, :description, :start_hour, :end_hour, :place, :integrated

@events.each do |event|
  node(:type_event) { ScheduleEvent.type_name_event(event.type_event) }
end
