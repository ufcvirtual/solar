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

  # recupera o "caminho" o qual a ferramenta pertence
  def parents_path
    # recupera as allocation_tags
    allocation_tags = self.academic_allocations.map(&:allocation_tag)
    parents_path = []

    # se não for para turmas ou for para uma turma
    if allocation_tags.map(&:group).include?(nil) or allocation_tags.map(&:group).compact.size == 1
      allocation_tags.each do |allocation_tag|
        path = []

        # pode pertencer a uma turma, oferta, curso ou uc
        group = allocation_tag.group
        offer = allocation_tag.offer || group.try(:offer)
        curriculum_unit = allocation_tag.curriculum_unit || offer.try(:curriculum_unit)
        course = allocation_tag.course || offer.try(:course)

        # monta string com o caminho o qual a ferramenta pertence
        path.insert(0, group.code) unless group.nil?
        path.insert(0, offer.semester.name) unless offer.nil?
        path.insert(0, curriculum_unit.name) unless curriculum_unit.nil?
        path.insert(0, course.name) unless course.nil?

        parents_path.insert(0, path.join(" - "))
      end
      parents_path
    else
      # quando tiver mais de uma turma, deve montar o caminho informando a quantidade de turmas
      first_group = allocation_tags.first.group
      [first_group.offer.course.name, first_group.offer.curriculum_unit.name, first_group.offer.semester.name, allocation_tags.count.to_s + " turmas"].join(" - ")
    end
    
  end

end
