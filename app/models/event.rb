module Event

  def self.included(base)
    # recupera os eventos que pertençam ao período visualizado e que tenham relação com as allocations_tags passadas
    base.scope :between, lambda {|start_time, end_time, allocation_tags| {joins: [:schedule, academic_allocations: :allocation_tag], conditions: ["
      ((schedules.end_date < ?) OR (schedules.start_date < ?)) AND ((schedules.start_date > ?) OR (schedules.end_date > ?))
      AND allocation_tags.id IN (?)", 
      format_date(end_time), format_date(end_time), format_date(start_time), format_date(start_time), allocation_tags] }}
  end

  # need to override the json view to return what full_calendar is expecting.
  # http://arshaw.com/fullcalendar/docs/event_data/Event_Object/
  def schedule_json(options = {})
    {
      id: id,
      title: respond_to?(:name) ? name : title, # o fullcalendar espera receber title
      description: (respond_to?(:enunciation) ? enunciation : description) || "",
      start: schedule.start_date,
      :end => schedule.end_date,
      allDay: (not respond_to?(:start_hour)), # se não tiver hora de inicio e fim é do dia todo
      recurring: (respond_to?(:start_hour) and respond_to?(:end_hour)), # se tiver hora de inicio e fim, é recorrente de todo dia no intervalo
      # repeats: (schedule.end_date.to_date - schedule.start_date.to_date),
      # repeat_freq: 1,
      # url: Rails.application.routes.url_helpers.assignment_path(id),
      start_hour: (respond_to?(:start_hour) ? start_hour : nil),
      end_hour: (respond_to?(:end_hour) ? end_hour : nil),
      color: verify_type(self.class.to_s)
    }
  end

  def self.format_date(date_time)
    Time.at(date_time.to_i).to_formatted_s(:db)
  end

  def verify_type(model_name)
    return (
      case model_name
        when "Assignment"
          "#CCCCFF"
        when "ChatRoom"
          "#A7C1F0"
        when "Discussion"
          "#CAFCCC"
        # when Prova presencial ou Encontro presencial
        # F5D5EF
        else
          "#FCEBCA"
      end
    )
  end

end
