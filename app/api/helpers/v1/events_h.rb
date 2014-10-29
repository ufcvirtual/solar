module V1::EventsH

  def get_event_type_and_description(type)
    case type.to_i
      when 1; {type: 2, title: "Encontro Presencial"} # encontro presencial
      when 2; {type: 1, title: "Prova Presencial: AP - 1ª chamada"} # prova presencial - AP - 1ª chamada
      when 3; {type: 1, title: "Prova Presencial: AP - 2ª chamada"} # prova presencial - AP - 2ª chamada
      when 4; {type: 1, title: "Prova Presencial: AF - 1ª chamada"} # prova presencial - AF - 1ª chamada
      when 5; {type: 1, title: "Prova Presencial: AF - 2ª chamada"} # prova presencial - AF - 2ª chamada
      when 6; {type: 5, title: "Aula por Web Conferência"} # aula por webconferência
    end
  end

  def def_attributes(params, schedule)
    event_info = get_event_type_and_description(params[:type])
    start_hour, end_hour = params[:start].split(":"), params[:end].split(":")
    {
      title: event_info[:title], type_event: event_info[:type], place: params[:place], start_hour: [start_hour[0], start_hour[1]].join(":"),
      end_hour: [end_hour[0], end_hour[1]].join(":"), schedule_id: schedule.id, integrated: true
    }
  end

  def def_attributes1(params, schedule)
    event_info = get_event_type_and_description(params[:Tipo])
    start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
    {
      title: event_info[:title], type_event: event_info[:type], place: params[:Polo], start_hour: [start_hour[0], start_hour[1]].join(":"),
      end_hour: [end_hour[0], end_hour[1]].join(":"), schedule_id: schedule.id, integrated: true
    }
  end

  def create_event(group, params)
    schedule = Schedule.create! start_date: params[:date], end_date: params[:date]
    event    = ScheduleEvent.create! def_attributes(params, schedule)
    event.academic_allocations.create! allocation_tag_id: group.allocation_tag.id

    {code: group.code, id: event.id}
  end

  def create_event1(group, params)
    schedule = Schedule.create! start_date: params[:Data], end_date: params[:Data]
    event    = ScheduleEvent.create! def_attributes1(params, schedule)
    event.academic_allocations.create! allocation_tag_id: group.allocation_tag.id

    {Codigo: group.code, id: event.id}
  end

end
