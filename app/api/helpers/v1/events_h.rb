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

  def send_email(id, verify_type='delete', old_start_date=nil, old_end_date=nil, old_start_hour=nil, old_end_hour=nil)
    event_ = ScheduleEvent.find(id)
    if event_.schedule.verify_by_to_date?
      files = Array.new
      event_.academic_allocations.each do |ac|
        emails = Array.new
        Allocation.where(allocation_tag_id: ac.allocation_tag_id).each do |al|
          emails.push(al.user.email)
        end  

        if verify_type == true
          template_mail = update_msg_template(ac.allocation_tag.info, event_, old_start_date, old_end_date, old_start_hour, old_end_hour)
          subject =  I18n.t('editions.mail.subject_update')
        elsif verify_type == 'delete'  
          template_mail = delete_msg_template(ac.allocation_tag.info, event_)
          subject = I18n.t('editions.mail.subject_delete')
        else
          template_mail = new_msg_template(ac.allocation_tag.info, event_)
          subject = I18n.t('editions.mail.subject_new')
        end 
        Thread.new do
          Job.send_mass_email(emails, subject, template_mail, files, nil)
        end 

      end  
    end
  end

  def new_msg_template(info, event_)
    start_date = event_.schedule.start_date.to_s + ' às '+ event_.start_hour
    end_date = event_.schedule.end_date.to_s + ' às '+ event_.end_hour
    %{
      Caros alunos, <br/>
      ________________________________________________________________________<br/><br/>
      Informamos que a atividade #{event_.title} do curso #{info} foi criada com o período de #{start_date}  à #{end_date}.
    }
  end 
  def update_msg_template(info, event_, old_start_date=nil, old_end_date=nil, old_start_hour=nil, old_end_hour=nil)
    start_date = event_.schedule.start_date.to_s + ' às '+ event_.start_hour
    end_date = event_.schedule.end_date.to_s + ' às '+ event_.end_hour
    if old_start_date.nil? || old_end_date.nil?
      copy_start_date = event_.schedule.copy_schedule.nil? ? start_date : event_.schedule.copy_schedule.start_date.to_s + ' às '+ old_start_hour
      copy_end_date = event_.schedule.copy_schedule.nil? ? end_date : event_.schedule.copy_schedule.end_date.to_s + ' às '+ old_end_hour
    else 
      copy_start_date = old_start_date.to_s + ' às '+ old_start_hour
      copy_end_date = old_end_date.to_s + ' às '+ old_end_hour
    end
 
    %{
      Caros alunos, <br/>
      ________________________________________________________________________<br/><br/>
      Informamos que a atividade #{event_.title} do curso #{info} teve seu período alterado de #{copy_start_date} à #{copy_end_date} para #{start_date} à #{end_date}.
    }
  end
  def delete_msg_template(info, event_)
    %{
      Caros alunos, <br/>
      ________________________________________________________________________<br/><br/>
      Informamos que a atividade #{event_.title} do curso #{info} foi removida.
    }
  end
end
