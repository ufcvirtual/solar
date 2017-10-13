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

  def create_event(params, ats, offer, old_event=nil)
    event_info = (params[:event][:type].blank? ? { type: params[:event][:type_event], title: params[:event][:title] } : get_event_type_and_description(params[:event][:type]))
    start_hour, end_hour = params[:event][:start].split(':'), params[:event][:end].split(':')
    group_events = []

    event = ScheduleEvent.joins(:schedule, :academic_allocations).where(schedules: { start_date: params[:event][:date], end_date: params[:event][:date] }, title: event_info[:title], type_event: event_info[:type], place: 'Polo', start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":"), integrated: true, academic_allocations: { allocation_tag_id: ats } ).first_or_initialize

    if event.new_record?
      schedule = Schedule.create! start_date: params[:event][:date], end_date: params[:event][:date]
      event.schedule_id = schedule.id
      event.save!
    end

    params[:groups].each do |code|
      group = get_offer_group(offer, code)

      old_ac = old_event.academic_allocations.where(allocation_tag_id: group.allocation_tag.id).first unless old_event.blank?
      ac_attributes = old_ac.blank? ? {} : old_ac.attributes.except('id', 'academic_tool_id', 'allocation_tag_id')

      if old_ac.blank?
        event.academic_allocations.where(allocation_tag_id: group.allocation_tag.id).first_or_create
      else
        old_ac.update_attributes(academic_tool_id: event.id)
      end

      group_events << {code: group.code, id: event.id}
    end

    group_events
  end

  def def_attributes1(params, schedule)
    event_info = get_event_type_and_description(params[:Tipo])
    start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
    {
      title: event_info[:title], type_event: event_info[:type], place: params[:Polo], start_hour: [start_hour[0], start_hour[1]].join(":"),
      end_hour: [end_hour[0], end_hour[1]].join(":"), schedule_id: schedule.id, integrated: true
    }
  end

  def create_event1(group, params)
    schedule = Schedule.create! start_date: params[:Data], end_date: params[:Data]
    event    = ScheduleEvent.create! def_attributes1(params, schedule)
    event.academic_allocations.create! allocation_tag_id: group.allocation_tag.id

    {Codigo: group.code, id: event.id}
  end
end
