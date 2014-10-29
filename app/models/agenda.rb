class Agenda # < ActiveRecord::Base

  def self.events(allocation_tags, date_search = nil, with_dates = false)
    events = if date_search.nil?
      Event.descendants.map{ |event| event.scoped.by_ats(allocation_tags) }.uniq
    else
      Event.descendants.map{ |event| event.scoped.of_today(date_search.to_date, allocation_tags) }.uniq
    end

    events = [events].flatten.map{|event| event.portlet_json({date: date_search.try(:to_date)})}.uniq

    if with_dates
      events_with_dates = events.collect do |schedule_event|
        schedule_end_date    = schedule_event[:end_date].nil? ? "" : schedule_event[:end_date].to_date
        [schedule_event[:start_date].to_date, schedule_end_date]
      end

      events_with_dates.flatten.uniq
    else
      events
    end
  end

end
