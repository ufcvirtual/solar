require 'active_support/concern'
module EvaluativeTool
  extend ActiveSupport::Concern

  def self.get_all(allocation_tags_ids = [])
    query = { academic_tool_type: self.descendants }
    query.merge!(allocation_tag_id: allocation_tags_ids) unless allocation_tags_ids.blank?

    AcademicAllocation.where(query)
  end

  def self.find_tools_in_common(ats)
    upper_ats = AllocationTag.find(ats.first).upper_related
    AcademicAllocation.find_by_sql <<-SQL
      SELECT *, ac.ats, ac.ids FROM academic_allocations
      JOIN (
        SELECT array_agg(id) AS ids, 
               academic_tool_id, 
               academic_tool_type, 
               array_agg(allocation_tag_id) AS ats
        FROM academic_allocations 
        WHERE academic_tool_type IN (#{"'"+self.descendants.join("','")+"'"})
        GROUP BY academic_tool_type, academic_tool_id 
        HAVING 
          array_agg(allocation_tag_id) @> ARRAY[#{ats.join(',')}]
          OR array_agg(allocation_tag_id) <@ ARRAY[#{upper_ats.join(',')}]
        ) ac ON ac.ids @> ARRAY[academic_allocations.id];
    SQL

  rescue => error
    raise "#{error}"
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
