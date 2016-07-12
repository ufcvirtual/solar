require 'active_support/concern'
module EvaluativeTool
  extend ActiveSupport::Concern

  def self.find_tools(ats)
    ats << AllocationTag.find(ats.first).lower_related if ats.size == 1
    AcademicAllocation.find_by_sql <<-SQL
      SELECT DISTINCT(ac.ids), *, ac.ats FROM academic_allocations
       JOIN (
         SELECT array_agg(id) AS ids, 
                academic_tool_id, 
                academic_tool_type, 
                array_agg(allocation_tag_id) AS ats
         FROM academic_allocations 
         WHERE academic_tool_type IN (#{"'"+self.descendants.join("','")+"'"}) 
         AND allocation_tag_id IN (#{ats.uniq.join(',')})
         GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight
         ) ac ON ac.ids @> ARRAY[academic_allocations.id];
    SQL
  end
 
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
