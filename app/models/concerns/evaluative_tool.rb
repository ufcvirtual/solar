require 'active_support/concern'
module EvaluativeTool
  extend ActiveSupport::Concern


  def self.get_all(allocation_tags_ids = [])
    query = { academic_tool_type: self.descendants }
    query.merge!(allocation_tag_id: allocation_tags_ids) unless allocation_tags_ids.blank?

    AcademicAllocation.where(query)
  end

  def self.find_tools_in_common(ats)
    # select array_agg(distinct allocation_tag_id) from academic_allocations group by academic_tool_type, academic_tool_id;

    #select array_agg(distinct id) from academic_allocations where allocation_tag_id IN (3,11) group by academic_tool_type, academic_tool_id;

# This query will give you a list of email addresses and how many times they're used, with the most used addresses first.

# select email, count(*) as c from table group by email having c >1 order by c desc
# If you want the full rows:

# select * from table where email in (
#     select email from table group by email having count(*) > 1
# )



  end

  # def self.find_tools_in_common(allocation_tags_ids)
  #   tools = EvaluativeTool.descendants.join(',').gsub(/[^,]+/, "'\\0'").html_safe
  #   return [] if tools.empty?
  #   allocation_tags_ids = allocation_tags_ids.split(' ').join(',')
  #   AcademicAllocation.find_by_sql <<-SQL
  #     SELECT DISTINCT ON (ac1.academic_tool_id, ac1.academic_tool_type, ac1.evaluative, ac1.frequency, ac1.final_exam, ac1.max_working_hours, ac1.weigth, ac1.equivalent_academic_allocation_id)
  #       ac1.academic_tool_id AS tool_id, ac1.academic_tool_type AS tool_type, ac1.id, ac1.evaluative, 
  #       ac1.frequency, ac1.final_exam, ac1.max_working_hours, ac1.weigth, ac1.equivalent_academic_allocation_id, (
  #           SELECT array_agg(DISTINCT ac3.allocation_tag_id) 
  #           FROM academic_allocations ac3 
  #           WHERE 
  #             ac3.academic_tool_id   = ac1.academic_tool_id   AND 
  #             ac3.academic_tool_type = ac1.academic_tool_type AND 
  #             ac3.evaluative = ac1.evaluative AND 
  #             ac3.frequency = ac1.frequency AND 
  #             ac3.final_exam = ac1.final_exam AND 
  #             ac3.weigth = ac1.weigth AND 
  #             ac3.max_working_hours = ac1.max_working_hours AND 
  #             ((ac3.equivalent_academic_allocation_id IS NULL AND ac1.equivalent_academic_allocation_id IS NULL) OR ac3.equivalent_academic_allocation_id = ac1.equivalent_academic_allocation_id) AND 
  #             ac3.allocation_tag_id IN (#{allocation_tags_ids})
  #         ) AS ats
  #     FROM academic_allocations ac1
  #       WHERE 
  #         ((
  #           SELECT array_agg(DISTINCT ac3.allocation_tag_id) 
  #           FROM academic_allocations ac3 
  #           WHERE 
  #             ac3.academic_tool_id   = ac1.academic_tool_id   AND 
  #             ac3.academic_tool_type = ac1.academic_tool_type AND 
  #             ac3.allocation_tag_id IN (#{allocation_tags_ids})
  #         ) @> (
  #           SELECT array_agg(DISTINCT id) FROM allocation_tags WHERE id IN (#{allocation_tags_ids})
  #         )) AND ac1.academic_tool_type IN (#{tools})
  #         AND ( ac1.academic_tool_type != 'ScheduleEvent' OR NOT EXISTS (
  #               SELECT * FROM schedule_events WHERE schedule_events.id = ac1.academic_tool_id AND (
  #                 schedule_events.type_event = #{Holiday} 
  #                 OR schedule_events.type_event = #{Recess}
  #             )))
  #       GROUP BY ac1.academic_tool_id, ac1.academic_tool_type, ac1.id, ac1.evaluative, ac1.frequency, ac1.final_exam, ac1.max_working_hours, ac1.weigth, ac1.equivalent_academic_allocation_id
  #       UNION
  #       SELECT DISTINCT ON (ac1.academic_tool_id, ac1.academic_tool_type, ac1.evaluative, ac1.frequency, ac1.final_exam, ac1.max_working_hours, ac1.weigth, ac1.equivalent_academic_allocation_id)
  #         ac1.academic_tool_id AS tool_id, ac1.academic_tool_type AS tool_type, ac1.id, ac1.evaluative, 
  #         ac1.frequency, ac1.final_exam, ac1.max_working_hours, ac1.weigth, ac1.equivalent_academic_allocation_id, array_agg(DISTINCT ac1.allocation_tag_id) AS ats
  #       FROM academic_allocations ac1
  #       JOIN related_taggables rt ON rt.group_at_id IN (#{allocation_tags_ids})
  #       WHERE 
  #         (
  #           ac1.allocation_tag_id = rt.offer_at_id OR
  #           ac1.allocation_tag_id = rt.course_at_id OR
  #           ac1.allocation_tag_id = rt.curriculum_unit_at_id
  #         ) AND ac1.academic_tool_type IN (#{tools})
  #         AND ( ac1.academic_tool_type != 'ScheduleEvent' OR NOT EXISTS (
  #               SELECT * FROM schedule_events WHERE schedule_events.id = ac1.academic_tool_id AND (
  #                 schedule_events.type_event = #{Holiday} 
  #                 OR schedule_events.type_event = #{Recess}
  #             )))
  #         GROUP BY ac1.academic_tool_id, ac1.academic_tool_type, ac1.id, ac1.evaluative, ac1.frequency, ac1.final_exam, ac1.max_working_hours, ac1.weigth, ac1.equivalent_academic_allocation_id, ac1.allocation_tag_id;
  #   SQL
  # end

  def full_period
    date = if respond_to?(:initial_time) 
            I18n.l(initial_time, format: :at_date)
           else
            hours  = (!respond_to?(:start_hour) || start_hour.nil?) ? '' : (!respond_to?(:end_hour) || end_hour.nil?) ? start_hour : [start_hour, end_hour].join(I18n.t('schedules.to'))
            dstart = respond_to?(:schedule) ?  I18n.l(schedule.start_date, format: :normal) : ''
            dend   = respond_to?(:schedule) ?  I18n.l(schedule.end_date, format: :normal) : ''
            I18n.t('editions.evaluative_tools.full_period', dstart: dstart, dend: dend , hours: hours)
           end
  end

  private

    def self.descendants
      ActiveRecord::Base.descendants.select{ |c|
        c.included_modules.include?(EvaluativeTool)
      }.map(&:name).map(&:to_s)
    end

end
