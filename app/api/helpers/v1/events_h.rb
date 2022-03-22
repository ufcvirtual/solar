module V1::EventsH
  extend Grape::API::Helpers
  def get_event_type_and_description(type)
    case type.to_i
      when 1; {type: 2, title: "Encontro Presencial"} # encontro presencial
      when 2; {type: 1, title: "Prova Presencial: AP - 1ª chamada"} # prova presencial - AP - 1ª chamada
      when 3; {type: 1, title: "Prova Presencial: AP - 2ª chamada"} # prova presencial - AP - 2ª chamada
      when 4; {type: 1, title: "Prova Presencial: AF - 1ª chamada"} # prova presencial - AF - 1ª chamada
      when 5; {type: 1, title: "Prova Presencial: AF - 2ª chamada"} # prova presencial - AF - 2ª chamada
      when 6; {type: 5, title: "Aula por Web Conferência"} # aula por webconferência
      when 7; {type: 7, title: "Avaliação Remota"}
    end
  end

  def create_event(params, ats, offer, existing_ac=nil, update_event=nil)
    if params[:Turmas].present?
      params[:groups] = params[:Turmas]
      params[:event] = params[:DataInserida]
      params[:event][:date] = params[:DataInserida][:Data]
      params[:event][:type] = params[:DataInserida][:Tipo]
      params[:event][:start] = params[:DataInserida][:HoraInicio]
      params[:event][:end] = params[:DataInserida][:HoraFim]
    end

    event_info = (params[:event][:type].blank? ? { type: params[:event][:type_event], title: params[:event][:title] } : get_event_type_and_description(params[:event][:type]))
    start_hour, end_hour = params[:event][:start].split(':'), params[:event][:end].split(':')
    group_events = []

    event = ScheduleEvent.joins(:schedule, :academic_allocations).where(schedules: { start_date: params[:event][:date], end_date: params[:event][:date] }, title: event_info[:title], type_event: event_info[:type], place: ([6,7].include?(event_info[:type]) ? 'Solar' : 'Polo'), start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":"), academic_allocations: { allocation_tag_id: ats } ).first_or_initialize
    event.integrated = true

    if event.new_record? && update_event.blank?
      schedule = Schedule.create! start_date: params[:event][:date], end_date: params[:event][:date]
      event.schedule_id = schedule.id
      event.integrated = true
      event.save!
    elsif event.new_record? && !update_event.blank? && !existing_ac.blank?
      event = update_event
      event.schedule.update_attributes! start_date: params[:event][:date], end_date: params[:event][:date]
      event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":"), integrated: true
    end

    if params[:groups].present?
      acs = []
      params[:groups].each do |group_name|
        group = get_offer_group(offer, group_name)
        ac = event.academic_allocations.where(allocation_tag_id: group.allocation_tag.id).first_or_initialize
        if ac.new_record?
          ac.merge = true
          ac.save!
          acs << ac
        end
        group_events << {name: group.name, Codigo: group.name, id: ac.id}
      end
      AcademicTool.send_email(event, acs, false)
    elsif !existing_ac.nil? && (event.id != update_event.try(:id))
      old_event = old_event = ScheduleEvent.find(existing_ac.academic_tool_id)
      existing_ac.update_attributes(academic_tool_id: event.id)
      if !event.new_record? && !update_event.blank?
        AcademicTool.send_email(event, [existing_ac], true, {start_date: update_event.schedule.start_date , end_date: update_event.schedule.end_date, start_hour: update_event.start_hour, end_hour: update_event.end_hour})
        update_event.api = true
        update_event.merge = true
        update_event.destroy
      else
        AcademicTool.send_email(event, [existing_ac], true, {start_date: old_event.schedule.start_date , end_date: old_event.schedule.end_date, start_hour: old_event.start_hour, end_hour: old_event.end_hour})
      end
    end

    group_events
  end

  # def def_attributes1(params, schedule)
  #   event_info = get_event_type_and_description(params[:Tipo])
  #   start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
  #   {
  #     title: event_info[:title], type_event: event_info[:type], place: params[:Polo], start_hour: [start_hour[0], start_hour[1]].join(":"),
  #     end_hour: [end_hour[0], end_hour[1]].join(":"), schedule_id: schedule.id, integrated: true
  #   }
  # end

  # def create_event1(group, params)
  #   schedule = Schedule.create! start_date: params[:Data], end_date: params[:Data]
  #   event    = ScheduleEvent.create! def_attributes1(params, schedule)
  #   event.academic_allocations.create! allocation_tag_id: group.allocation_tag.id
  #   {Codigo: group.name, id: event.id}
  # end
end
