class Agenda

  def self.events(allocation_tags, date_search = nil, with_dates = false)
    date_search = date_search.blank? ? nil : date_search.to_date.to_formatted_s(:db)
    query = if date_search.blank?
      ''
    else
      "WHERE ('#{date_search}' BETWEEN schedules.start_date AND schedules.end_date)"
    end

    sql = []
    unless allocation_tags.blank?
      Event.descendants.map(&:table_name).each do |table|
        unless table == 'lessons'
          sql_each = []
          sql_each << <<-SQL
            SELECT  DISTINCT tb.id,
                    schedules.start_date AS start_date, 
                    schedules.end_date   AS end_date,
          SQL

          sql_each << case
          when table == 'assignments'
            'tb.enunciation AS description,
             tb.name AS name'
          when ['lessons', 'discussions', 'exams'].include?(table)
            'tb.description AS description,
             tb.name AS name'
          else
            'tb.description AS description,
             tb.title AS name'
          end

          sql_each << <<-SQL
            FROM #{table} tb
              JOIN schedules ON tb.schedule_id = schedules.id
          SQL

          if table == 'lessons'
            sql_each << <<-SQL
                JOIN lesson_modules ON lesson_modules.id = tb.lesson_module_id
                JOIN academic_allocations ON lower(academic_allocations.academic_tool_type) = 'lessonmodule' AND academic_allocations.academic_tool_id = lesson_modules.id AND academic_allocations.allocation_tag_id IN (#{allocation_tags.join(',')})
                #{query} AND lessons.status = 1 AND lessons.address IS NOT NULL
            SQL
          else
            sql_each << <<-SQL
                JOIN academic_allocations ON lower(academic_allocations.academic_tool_type) = replace(regexp_replace('#{table}', 's$', ''), '_', '') AND academic_allocations.academic_tool_id = tb.id AND academic_allocations.allocation_tag_id IN (#{allocation_tags.join(',')})
                #{query}
            SQL
          end
          sql << sql_each.join('')
        end
      end
    end

    events = ActiveRecord::Base.connection.execute sql.join(' UNION ALL ') || []

    if with_dates
      events_with_dates = events.collect do |schedule_event|
        schedule_end_date    = schedule_event['end_date'].nil? ? '' : schedule_event['end_date'].to_date
        [schedule_event['start_date'].to_date, schedule_end_date]
      end

      events_with_dates.flatten.uniq
    else
      events
    end
  end

end
