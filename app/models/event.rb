class Event < ActiveRecord::Base
  self.abstract_class = true

  # recupera os eventos que pertençam ao periodo visualizado e que tenham relação com as allocations_tags passadas
  scope :between, -> (start_time, end_time, allocation_tags) { joins(:schedule, academic_allocations: :allocation_tag).where('
    ((schedules.end_date < ?) OR (schedules.start_date < ?)) AND ((schedules.start_date > ?) OR (schedules.end_date > ?))
    AND allocation_tags.id IN (?)', format_date(end_time), format_date(end_time), format_date(start_time), format_date(start_time), allocation_tags) }


  # recupera os eventos que vao iniciar "de hoje em diante" ou ja começaram, mas ainda vao terminar
  scope :after, -> (today, allocation_tags) { joins(:schedule, academic_allocations: :allocation_tag).where('
    ((schedules.start_date >= ?) OR (schedules.end_date >= ?)) AND allocation_tags.id IN (?)',
    format_date(today.to_date), format_date(today.to_date), allocation_tags) }

  # recupera os eventos que englobam o dia de hoje
  scope :of_today, -> (day, allocation_tags) { joins(:schedule, academic_allocations: :allocation_tag).where('
    (? BETWEEN schedules.start_date AND schedules.end_date) AND allocation_tags.id IN (?)',
    format_date(day.to_date), allocation_tags) }

  scope :by_ats, -> (allocation_tags) { joins(academic_allocations: :allocation_tag).where('allocation_tags.id IN (?)', allocation_tags) }

  CANT_EDIT = ['lesson']

  def api_json
    has_start_hour, has_end_hour = (respond_to?(:start_hour) && !start_hour.blank?), (respond_to?(:end_hour) && !end_hour.blank?)
    {
      type: api_type,
      title: respond_to?(:name) ? name : title,
      start_date: schedule.start_date,
      end_date: schedule.end_date,
      all_day: !has_start_hour, # se nao tiver hora de inicio e fim eh do dia todo
      start_hour: (has_start_hour ? start_hour : nil),
      end_hour: (has_end_hour ? end_hour : nil)
    }
  end

  def schedule_json
    has_start_hour, has_end_hour = (respond_to?(:start_hour) && !start_hour.blank?), (respond_to?(:end_hour) && !end_hour.blank?)
    {
      id: id,
      title: respond_to?(:name) ? name : title, # o fullcalendar espera receber title
      description: (respond_to?(:enunciation) ? enunciation : description) || '',
      start: schedule.start_date,
      :end => schedule.end_date, # || academic_allocations.map(&:allocation_tag).first.offer.end_date,
      allDay: !has_start_hour, # se nao tiver hora de inicio e fim eh do dia todo
      recurring: (has_start_hour && has_end_hour), # se tiver hora de inicio e fim, eh recorrente de todo dia no intervalo
      start_hour: (has_start_hour ? start_hour : nil),
      end_hour: (has_end_hour ? end_hour : nil),
      color: verify_type,
      type: self.class.name,
      type_full: (self.class.name == 'ScheduleEvent' ? I18n.t("schedule_events.types.#{type_name}") : I18n.t('fullcalendar.type_full', type: I18n.t(self.class.name.tableize.singularize.to_sym, scope: [:activerecord, :models]))),
      dropdown_path: Rails.application.routes.url_helpers.send("dropdown_content_of_#{self.class.name.to_s.tableize.singularize}_path", id: id, allocation_tags_ids: 'all_params')
    }
  end

  def self.format_date(date_time)
    date_time.to_formatted_s(:db)
  end

  def api_type
    api_t = self.class.name.underscore

    if api_t == 'schedule_event'
      api_t = case type_event
              when Presential_Test; 'presential_test'
              when Presential_Meeting; 'presential_meeting'
              when WebConferenceLesson; 'web_conference_lesson'
              when Other; 'other'
              else 'recess_or_holiday'; end
    end
    api_t
  end

  def verify_type
    case api_type
    when 'assignment'; '#FCEBCA'
    when 'chat_room'; '#A7C1F0'
    when 'discussion'; '#CAFCCC'
    when 'lesson'; '#A9F0F7'
    when 'presential_test'; '#F5D5EF'
    when 'presential_meeting'; '#FFD9E0'
    when 'web_conference_lesson'; '#F5DA81'
    when 'recess_or_holiday'; '#E3E3E3'
    when 'exam'; '#E4FFA5'
    else
      '#CCCCFF'
    end
  end

  def parents_path
    allocation_tags = self.academic_allocations.map(&:allocation_tag)
    first_at, count_groups = allocation_tags.first, allocation_tags.count

    ((first_at.group.nil? || count_groups == 1) ? first_at.info : [first_at.group.offer.info,  count_groups.to_s + I18n.t('agendas.dropdown_content.groups')].join(' - '))
  end

  def self.all_descendants(allocation_tags_ids, user, list = false, params = {})

    (Event.descendants.map do |event|
      limited = event.limited(user, allocation_tags_ids) if event.respond_to?(:limited)
       if list

        events = event.after(Date.today, allocation_tags_ids)
        puts 'TESTE'
        p event.object_id
        p event
      else
        start_date, end_date =  if params[:semester]
                                  [params[:start], params[:end]]
                                else
                                  [Time.at(params['start'].to_i), Time.at(params['end'].to_i)]
                                end
        events = event.between(start_date, end_date, allocation_tags_ids)
      end
      p events       
      (limited.nil? ? events : (limited & events))
    end).uniq
  end

  def name_portlet(options = {})
    [
      case
      when (options.nil? || options[:date].nil?)                    then nil
      when schedule.start_date.to_date == schedule.end_date.to_date then nil
      when options[:date].to_date == schedule.start_date.to_date    then I18n.t('agendas.begin_of')
      when options[:date].to_date == schedule.end_date.to_date      then I18n.t('agendas.end_of')
      end,
      respond_to?(:name) ? name : title
    ].join('')
  end
end
