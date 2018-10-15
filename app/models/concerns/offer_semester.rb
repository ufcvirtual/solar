require 'active_support/concern'

module OfferSemester
  extend ActiveSupport::Concern

  included do
    validate :verify_activities, on: :update, unless: Proc.new { |tag| tag.new_record? }
    after_update :update_activities

    attr_accessor :api
  end

  def update_activities
    schedule = if self.class.to_s == 'Offer'
      changed_schedule = (deleted_schedule || (!period_schedule.blank? && period_schedule.new_record?))
      (changed_schedule && deleted_schedule) ? semester.offer_schedule : period_schedule
    elsif self.class.to_s == 'Semester'
      offer_schedule
    end

    return true if !changed_schedule && (schedule.previous_changes[:start_date].blank? && schedule.previous_changes[:end_date].blank?)

    start_date = schedule.start_date
    end_date = schedule.end_date

    warnings = []

    # Thread.new do
      ActiveRecord::Base.connection

      unless (end_date.blank? || start_date.blank?)
        offers = (self.class.to_s == 'Semester') ? self.offers.where(offer_schedule_id: nil) : [self]

        offers.each do |offer|

          ats = offer.allocation_tag.related
          academic_allocation = AcademicAllocation.includes(:academic_allocation_users).where(allocation_tag_id: ats, academic_allocation_users: {id: nil})
          emails = User.with_access_on('receive_academic_tool_notification','emails',ats, true).map(&:email).compact.uniq

          activities_to_email = {}
          activities_to_save = []
          Struct.new('Activity',:name, :start_date, :end_date, :tool)

          academic_allocation.each do |ac|
            tool = ac.academic_tool
            tool_name = tool.respond_to?(:name) ? tool_name : tool.title
            model_name = Object.const_get(ac.academic_tool_type).model_name.human

            if ['Assignment', 'Discussion', 'ChatRoom', 'Notification', 'ScheduleEvent', 'Exam'].include?(ac.academic_tool_type) && (!tool.respond_to?(:integrated) || !tool.integrated)

              diff_days = (tool.schedule.end_date - tool.schedule.start_date).to_i

              if tool.schedule.start_date < start_date
                tool.schedule.start_date = start_date
                tool.schedule.end_date = start_date if diff_days == 0
              end

              if tool.schedule.end_date > end_date
                tool.schedule.end_date = end_date
                tool.schedule.start_date = end_date if diff_days == 0
              elsif diff_days > 0
                new_end_date = start_date + diff_days.days
                if new_end_date <= end_date
                  tool.schedule.end_date = new_end_date
                else
                  tool.schedule.end_date = end_date
                end
              end

              if tool.schedule.changed?
                  struct = Struct::Activity.new(tool_name, tool.schedule.start_date.to_s, tool.schedule.end_date.to_s, model_name)
                  activities_to_email[ac.academic_tool_type] ||= []
                  activities_to_email[ac.academic_tool_type] << struct
                  activities_to_save << tool
              end

            end # assignment

            if ['Webconference'].include? ac.academic_tool_type
              tool.initial_time = Time.new(start_date.year, start_date.month, start_date.day, tool.initial_time.hour, tool.initial_time.min, tool.initial_time.sec) if tool.initial_time < start_date

              tool.initial_time = Time.new(end_date.year, end_date.month, end_date.day, tool.initial_time.hour, tool.initial_time.min, tool.initial_time.sec) if tool.initial_time > end_date

              if tool.changed?
                struct = Struct::Activity.new(tool.title, tool.initial_time.to_date.to_s, tool.initial_time.to_date.to_s, model_name)
                activities_to_email[ac.academic_tool_type] ||= []
                activities_to_email[ac.academic_tool_type] << struct
                activities_to_save << tool
              end

            end # web

            if ['LessonModule'].include? ac.academic_tool_type
              lessons = tool.lessons

              lessons.each do |lesson|
                lesson.schedule.start_date = start_date if lesson.schedule.start_date < start_date

                lesson.schedule.end_date = end_date if lesson.schedule.end_date != nil && lesson.schedule.end_date  > end_date

                if lesson.schedule.changed?
                  struct = Struct::Activity.new(lesson.name, lesson.schedule.start_date.to_s, lesson.schedule.end_date.to_s, model_name)
                  activities_to_email[ac.academic_tool_type] ||= []
                  activities_to_email[ac.academic_tool_type] << struct
                  activities_to_save << lesson
                end

              end # lesson

            end # module

          end # ac

          unless activities_to_save.blank?
            ActiveRecord::Base.transaction do
              activities_to_save.each do |activity|
                activity.merge = true
                activity.save(validate: false)
              end
            end

            # Job.send_mass_email(emails, I18n.t('notifier.activities_update.subject'), email_template(activities_to_email)) unless activities_to_email.blank?
          end
        end # offer
      end # unless
    #   ActiveRecord::Base.connection.close
    # end # thread
  end

  def msg_template(activities)
    html = ""
    activities.each do |key, value|
      value.each do |object|
        if key == "Webconference"
          html << I18n.t('notifier.activities_update.change', activity: object.tool, activity_name: object.name, date: object.start_date)
        else
          html << I18n.t('notifier.activities_update.change', activity: object.tool, activity_name: object.name, date_start: object.start_date, date_end: object.end_date)
        end
      end
    end
    html
  end

  def email_template(activities)
    %{#{msg_template(activities)}}
  end

  def verify_activities
    schedule = if self.class.to_s == 'Offer'
      changed_schedule = (deleted_schedule || (!period_schedule.blank? && period_schedule.new_record?))
      (changed_schedule && deleted_schedule) ? semester.offer_schedule : period_schedule
    elsif self.class.to_s == 'Semester'
      offer_schedule
    end

    # schedule id changed e data diferente da oferta (inicio depois ou fim antes)
    unless changed_schedule
      return true if (api.nil? && schedule.start_date == schedule.start_date_was && schedule.end_date == schedule.end_date_was)
      return true if (!api.nil? && schedule.previous_changes[:start_date].blank? && schedule.previous_changes[:end_date].blank?)
    end

    offers = (self.class.to_s == 'Semester') ? self.offers.where(offer_schedule_id: nil) : [self]

    ats = offers.map(&:allocation_tag).map(&:related).flatten.uniq
    # se  o inicio ou fim tiverem sido afetados e tiver acu, deve dar erro
    activities_with_acu = AcademicAllocation.joins(:academic_allocation_users).where(allocation_tag_id: ats).where("academic_tool_type != 'Webconference'")
    web_with_access = AcademicAllocation.joins(:log_actions).where(academic_tool_type: 'Webconference', log_actions: {log_type: 7}, allocation_tag_id: ats)

    return true if activities_with_acu.empty? && web_with_access.empty?

    afected_by_date_change = []

    afected_by_date_change = activities_with_acu.select{|ac| ac.schedule.start_date < schedule.start_date || ac.schedule.start_date > schedule.end_date || ac.schedule.end_date < schedule.start_date || ac.schedule.end_date > schedule.end_date }

    raise 'afected_by_date' if afected_by_date_change.any?

    afected_by_date_change = web_with_access.select{|ac| ac.schedule < schedule.start_date || ac.schedule > schedule.end_date }

    raise 'afected_by_date' if afected_by_date_change.any?
  end

end