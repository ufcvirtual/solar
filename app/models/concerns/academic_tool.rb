require 'active_support/concern'

module AcademicTool
  extend ActiveSupport::Concern

  included do
    has_many :academic_allocations, as: :academic_tool, dependent: :destroy
    has_many :allocation_tags, through: :academic_allocations
    has_many :groups, through: :allocation_tags
    has_many :offers, through: :allocation_tags

    after_create :define_academic_associations, unless: 'allocation_tag_ids_associations.nil?'

    before_validation :set_schedule, if: 'respond_to?(:schedule) && merge.nil?'

    before_save :set_situation_date, if: 'merge.nil?', on: :update

    attr_accessor :allocation_tag_ids_associations, :merge
  end

  def offer_opened?
    !allocation_tags.map(&:verify_offer_period).include?(false)
  end

  def self.last_date(at, ac_id=nil)
    where = ac_id.blank? ? '' : " AND ac.id != #{ac_id}"

    date = AcademicAllocation.find_by_sql <<-SQL
      SELECT MAX(ed) AS max_date, ac_id
      FROM 
        ( 
          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM assignments 
          JOIN schedules ON schedules.id = assignments.schedule_id 
          JOIN academic_allocations ac ON ac.academic_tool_id = assignments.id AND academic_tool_type = 'Assignment'
          WHERE ac.allocation_tag_id = #{at} AND evaluative = 't' AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION 

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM discussions 
          JOIN schedules ON schedules.id=discussions.schedule_id 
          JOIN academic_allocations ac ON ac.academic_tool_id = discussions.id AND academic_tool_type = 'Discussion'
          WHERE ac.allocation_tag_id = #{at} AND evaluative = 't' AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION 

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM chat_rooms 
          JOIN schedules on schedules.id = chat_rooms.schedule_id 
          JOIN academic_allocations ac ON ac.academic_tool_id = chat_rooms.id AND academic_tool_type = 'ChatRoom'
          WHERE ac.allocation_tag_id = #{at} AND evaluative = 't' AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION 

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM exams 
          JOIN schedules on schedules.id = exams.schedule_id 
          JOIN academic_allocations ac ON ac.academic_tool_id = exams.id AND academic_tool_type = 'Exam'
          WHERE ac.allocation_tag_id = #{at} AND evaluative = 't' AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION 

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM schedule_events
          JOIN schedules on schedules.id = schedule_events.schedule_id 
          JOIN academic_allocations ac ON ac.academic_tool_id = schedule_events.id AND academic_tool_type = 'ScheduleEvent'
          WHERE ac.allocation_tag_id = #{at} AND evaluative = 't' AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION 

          SELECT MAX((initial_time + (interval '1 mins')*duration)::date) AS ed, ac.id AS ac_id
          FROM webconferences
          JOIN academic_allocations ac ON ac.academic_tool_id = webconferences.id AND academic_tool_type = 'Webconference'
          WHERE ac.allocation_tag_id = #{at} AND evaluative = 't' AND final_exam = 'f' #{where}
          GROUP BY ac.id

        ) dates
        GROUP BY ac_id
        ORDER BY max_date DESC
        LIMIT 1;
    SQL

    max_date = date.first.max_date.to_date + 2.days

    while(max_date.saturday? || max_date.sunday?)
      max_date = max_date + 1.day
    end

    {date: max_date, ac_id: date.first.ac_id}
  end

  private

    def define_academic_associations
      unless allocation_tag_ids_associations.blank?
        academic_allocations.create allocation_tag_ids_associations.map {|at| { allocation_tag_id: at }}
      else
        academic_allocations.create
      end
    end

    def set_schedule
      self.schedule.check_end_date = true # mandatory final date
      self.schedule.verify_offer_ats = allocation_tag_ids_associations
    end

    def set_situation_date
      # if changed end date
      if (respond_to?(:schedule) && self.schedule.end_date_changed?) || (respond_to?(:initial_time) && initial_time_changed?)
        end_date = (respond_to?(:schedule) ? schedule.end_date : initial_time) + 2.days
        while(end_date.saturday? || end_date.sunday?)
          end_date = end_date + 1.day
        end

        academic_allocations.each do |ac|
          at = ac.allocation_tag
          # if is last date to set situation and date is bigger, update date
          if at.situation_date_ac_id == ac.id && (!at.situation_date.blank? && end_date > at.situation_date)
            at.update_attributes situation_date: end_date
          # if is last date to set situation and date is smaller, search date
          elsif at.situation_date_ac_id == ac.id && (!at.situation_date.blank? && end_date < at.situation_date)
            last_date = AcademicTool.last_date(at.id, ac.id)
            at.update_attributes situation_date: last_date[:date], situation_date_ac_id: last_date[:ac_id]
          # if is not last date to set situation and date is bigger, update date and ac
          elsif (!at.situation_date.blank? && end_date > at.situation_date)
            at.update_attributes situation_date: end_date, situation_date_ac_id: ac.id
          end
        end
      end
    end

end
