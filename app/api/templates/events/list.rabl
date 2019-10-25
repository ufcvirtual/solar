collection @events, :root => :events

node do |event|
  {
    name: event.name,
    start_date: event.start_date.to_date,
    end_date: event.end_date.to_date,
    start_hour: event.start_hour,
    end_hour: event.end_hour,
    type_event: ScheduleEvent.type_name_event(event.type_event.to_i),
    situation: event.situation,
    place: event.place,
    evaluative: event.evaluative,
    frequency: event.frequency
  }
end
