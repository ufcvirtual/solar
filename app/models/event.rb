class Event < ActiveRecord::Base
  self.abstract_class = true

  # recupera os eventos que pertençam ao período visualizado e que tenham relação com as allocations_tags passadas
  scope :between, lambda {|start_time, end_time, allocation_tags| {joins: [:schedule, academic_allocations: :allocation_tag], conditions: ["
    ((schedules.end_date < ?) OR (schedules.start_date < ?)) AND ((schedules.start_date > ?) OR (schedules.end_date > ?))
    AND allocation_tags.id IN (?)", 
    format_date(end_time), format_date(end_time), format_date(start_time), format_date(start_time), allocation_tags] }}
  # recupera os eventos que vão iniciar "de hoje em diante" ou já começaram, mas ainda vão terminar
  scope :after, lambda {|today, allocation_tags| {joins: [:schedule, academic_allocations: :allocation_tag], conditions: ["
    ((schedules.start_date >= ?) OR (schedules.end_date >= ?)) AND allocation_tags.id IN (?)", 
    today, today, allocation_tags] }}

  def schedule_json(options = {})
    {
      id: id,
      title: respond_to?(:name) ? name : title, # o fullcalendar espera receber title
      description: (respond_to?(:enunciation) ? enunciation : description) || "",
      start: schedule.start_date,
      :end => schedule.end_date,
      allDay: (not respond_to?(:start_hour) or start_hour.blank?), # se não tiver hora de inicio e fim é do dia todo
      recurring: (respond_to?(:start_hour) and respond_to?(:end_hour) and not(start_hour.blank? or end_hour.blank?)), # se tiver hora de inicio e fim, é recorrente de todo dia no intervalo
      start_hour: (respond_to?(:start_hour) ? start_hour : nil),
      end_hour: (respond_to?(:end_hour) ? end_hour : nil),
      color: verify_type(self.class.to_s, (respond_to?(:type_event) ? type_event : nil)),
      type: self.class.name,
      dropdown_path: Rails.application.routes.url_helpers.send("dropdown_content_of_#{self.class.name.to_s.tableize.singularize}_path", id: id, allocation_tags_ids: 'all_params')
    }
  end

  def self.format_date(date_time)
    Time.at(date_time.to_i).to_formatted_s(:db)
  end

  def verify_type(model_name, type_event)
    return (
      case model_name
        when "Assignment"
          "#CCCCFF"
        when "ChatRoom"
          "#A7C1F0"
        when "Discussion"
          "#CAFCCC"
        when "ScheduleEvent"
          if type_event == 1
            "#F5D5EF"
          elsif type_event == 2
            "#FFD9E0"
          else
            "#E3E3E3"
          end
        else
          "#FCEBCA"
      end
    )
  end

end
