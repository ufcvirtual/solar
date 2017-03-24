require 'active_support/concern'
module EvaluativeTool
  extend ActiveSupport::Concern

  included do
    has_many :academic_allocation_users, through: :academic_allocations
  end

  def self.find_tools(ats)
    ats << AllocationTag.find(ats.first).lower_related if ats.size == 1
    ats = ats.uniq.join(',')
    AcademicAllocation.find_by_sql <<-SQL
      SELECT DISTINCT
        array_agg(academic_allocations.id) AS ids, 
        max(academic_allocations.id) AS id,
        academic_tool_id, 
        academic_tool_type,
        evaluative, 
        frequency,
        final_weight,
        weight, 
        final_exam,
        max_working_hours,
        equivalent_academic_allocation_id,
        array_agg(allocation_tag_id) AS ats, 
        name AS name, 
        enunciation AS description,
        schedules.start_date AS start_date,
        schedules.end_date AS end_date,
        start_hour AS start_hour,
        end_hour AS end_hour
      FROM academic_allocations 
      LEFT JOIN assignments ON assignments.id = academic_tool_id AND academic_tool_type = 'Assignment' 
      LEFT JOIN schedules ON schedules.id = schedule_id
      WHERE academic_tool_type = 'Assignment'
        AND allocation_tag_id IN (#{ats})
      GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight, name, enunciation, start_date, end_date, start_hour, end_hour

      UNION(
        SELECT DISTINCT
          array_agg(academic_allocations.id) AS ids, 
          max(academic_allocations.id) AS id,
          academic_tool_id, 
          academic_tool_type, 
          evaluative, 
          frequency,
          final_weight,
          weight, 
          final_exam,
          max_working_hours,
          equivalent_academic_allocation_id,
          array_agg(allocation_tag_id) AS ats, 
          name AS name, 
          description AS description,
          schedules.start_date AS start_date,
          schedules.end_date AS end_date,
          '' AS start_hour,
          '' AS end_hour
        FROM academic_allocations 
        LEFT JOIN discussions ON discussions.id = academic_tool_id AND academic_tool_type = 'Discussion' 
        LEFT JOIN schedules ON schedules.id = schedule_id
        WHERE academic_tool_type = 'Discussion'
          AND allocation_tag_id IN (#{ats})
        GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight, name, description, start_date, end_date
      )

      UNION(
        SELECT DISTINCT
          array_agg(academic_allocations.id) AS ids, 
          max(academic_allocations.id) AS id,
          academic_tool_id, 
          academic_tool_type, 
          evaluative, 
          frequency,
          final_weight,
          weight, 
          final_exam,
          max_working_hours,
          equivalent_academic_allocation_id,
          array_agg(allocation_tag_id) AS ats, 
          title AS name, 
          description AS description,
          schedules.start_date AS start_date,
          schedules.end_date AS end_date,
          start_hour AS start_hour,
          end_hour AS end_hour
        FROM academic_allocations 
        LEFT JOIN chat_rooms ON chat_rooms.id = academic_tool_id AND academic_tool_type = 'ChatRoom' 
        LEFT JOIN schedules ON schedules.id = schedule_id
        WHERE academic_tool_type = 'ChatRoom'
          AND allocation_tag_id IN (#{ats})
        GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight, title, description, start_date, end_date, start_hour, end_hour
      )

      UNION(
        SELECT DISTINCT
          array_agg(academic_allocations.id) AS ids, 
          max(academic_allocations.id) AS id,
          academic_tool_id, 
          academic_tool_type,
          evaluative, 
          frequency,
          final_weight,
          weight, 
          final_exam,
          max_working_hours,
          equivalent_academic_allocation_id, 
          array_agg(allocation_tag_id) AS ats, 
          name AS name, 
          description AS description,
          schedules.start_date AS start_date,
          schedules.end_date AS end_date,
          start_hour AS start_hour,
          end_hour AS end_hour
        FROM academic_allocations 
        LEFT JOIN exams ON exams.id = academic_tool_id AND academic_tool_type = 'Exam' 
        LEFT JOIN schedules ON schedules.id = schedule_id
        WHERE academic_tool_type = 'Exam'
          AND allocation_tag_id IN (#{ats})
          AND exams.status = 't'
        GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight, name, description, start_date, end_date, start_hour, end_hour
      )

      UNION(
        SELECT DISTINCT
          array_agg(academic_allocations.id) AS ids, 
          max(academic_allocations.id) AS id,
          academic_tool_id, 
          academic_tool_type, 
          evaluative, 
          frequency,
          final_weight,
          weight, 
          final_exam,
          max_working_hours,
          equivalent_academic_allocation_id,
          array_agg(allocation_tag_id) AS ats, 
          title AS name, 
          description AS description,
          schedules.start_date AS start_date,
          schedules.end_date AS end_date,
          start_hour AS start_hour,
          end_hour AS end_hour
        FROM academic_allocations 
        LEFT JOIN schedule_events ON schedule_events.id = academic_tool_id AND academic_tool_type = 'ScheduleEvent' 
        LEFT JOIN schedules ON schedules.id = schedule_id
        WHERE academic_tool_type = 'ScheduleEvent'
          AND allocation_tag_id IN (#{ats})
          AND (schedule_events.type_event != #{Recess} AND schedule_events.type_event != #{Holiday})
        GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight, title, description, start_date, end_date, start_hour, end_hour
      )
      
      UNION(
        SELECT DISTINCT
          array_agg(academic_allocations.id) AS ids, 
          max(academic_allocations.id) AS id,
          academic_tool_id, 
          academic_tool_type, 
          evaluative, 
          frequency,
          final_weight,
          weight, 
          final_exam,
          max_working_hours,
          equivalent_academic_allocation_id,
          array_agg(allocation_tag_id) AS ats, 
          title AS name, 
          description AS description,
          webconferences.initial_time AS start_date,
          (webconferences.initial_time + duration* interval '1 min') AS end_date,
          initial_time::text AS start_hour,
          (initial_time + duration* interval '1 min')::text AS end_hour
        FROM academic_allocations 
        LEFT JOIN webconferences ON webconferences.id = academic_tool_id AND academic_tool_type = 'Webconference' 
        WHERE academic_tool_type = 'Webconference'
          AND allocation_tag_id IN (#{ats})
        GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight, title, description, initial_time, duration
      )
    
      ORDER BY academic_tool_type, name;

    SQL
  end

  def verify_evaluatives
    academic_allocations.where('evaluative IS TRUE OR frequency IS TRUE').any?
  end

  def can_remove_groups_with_raise
    raise 'dependencies' unless can_remove_groups?
  end

  # filled groups: at groups_controller ; empty groups: before_destroy
  def can_remove_groups?(groups=[])
    begin
      case self.class.to_s
      when 'Assignment'
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: self.id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      when 'Discussion'
        if groups.any?
          discussion_posts.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          discussion_posts.empty?
        end
      when 'Exam'
        return false if status && on_going?
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'Exam', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      when 'ChatRoom'
        if groups.any?
          user_messages.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          user_messages.empty?
        end
      when 'Webconference'
        return false unless can_destroy?
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'Webconference', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      when 'ScheduleEvent'
        return false unless can_change?
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'ScheduleEvent', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      else
        true
      end
    rescue => error
      return false
    end
  end

  # filled groups: at groups_controller ; empty groups: before_destroy
  def can_unbind?(groups=[])
    case self.class.to_s
    when 'Exam'
      !(status && on_going?)
    when 'Webconference'
      records = 0
      if shared_between_groups?
        records = recordings.size
      elsif groups.blank?
        allocation_tags.each do |at|
          records += recordings([], at.id).size
          return false if records > 0
        end
      else
        groups.each do |group|
          records += recordings([], group.allocation_tag.id).size
          return false if records > 0
        end
      end

      !started? || (is_over? && records == 0)
    else
      true
    end
  end

  def self.count_tools(ats)
    ac = AcademicAllocation.find_by_sql <<-SQL
        SELECT COUNT(exams.id) AS exams_count, COUNT(assignments.id) AS assignments_count, COUNT(discussions.id) AS discussions_count, COUNT(schedule_events.id) AS events_count, COUNT(webconferences.id) AS webconferences_count, COUNT(chat_rooms.id) AS chat_rooms_count
        FROM academic_allocations 
        LEFT JOIN exams ON academic_allocations.academic_tool_type = 'Exam' AND exams.id = academic_allocations.academic_tool_id
        LEFT JOIN assignments ON academic_allocations.academic_tool_type = 'Assignment' AND assignments.id = academic_allocations.academic_tool_id
        LEFT JOIN discussions ON academic_allocations.academic_tool_type = 'Discussion' AND discussions.id = academic_allocations.academic_tool_id
        LEFT JOIN schedule_events ON academic_allocations.academic_tool_type = 'ScheduleEvent' AND schedule_events.id = academic_allocations.academic_tool_id
        LEFT JOIN webconferences ON academic_allocations.academic_tool_type = 'Webconference' AND webconferences.id = academic_allocations.academic_tool_id
        LEFT JOIN chat_rooms ON academic_allocations.academic_tool_type = 'ChatRoom' AND chat_rooms.id = academic_allocations.academic_tool_id
        WHERE academic_tool_type IN (#{"'"+self.descendants.join("','")+"'"}) 
        AND (academic_allocations.academic_tool_type != 'Exam' OR exams.status = true)
        AND academic_allocations.allocation_tag_id IN (#{ats})
        LIMIT 1;
      SQL
      ac.first
  end

  private
    def self.descendants
      ActiveRecord::Base.descendants.select{ |c|
        c.included_modules.include?(EvaluativeTool)
      }.map(&:name).map(&:to_s)
    end
end
