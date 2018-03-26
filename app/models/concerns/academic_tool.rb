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

    after_update if: 'notify_change?' do
      send_email(true)
    end

    attr_accessor :allocation_tag_ids_associations, :merge
  end

  def notify_change?
    (
      allocation_tags.any? && merge.nil? && (
        (
          respond_to?(:schedule) && (schedule.previous_changes.has_key?(:start_date) || schedule.previous_changes.has_key?(:end_date))
        ) || (
          respond_to?(:initial_time) && (initial_time_changed? || duration_changed?)
        ) || (
          respond_to?(:start_hour) && (start_hour_changed? || end_hour_changed?)
        ) || (
          respond_to?(:status_changed?) && status_changed?
        )
      ) && verify_start
    )

  end

  def verify_start
    (
      (
        respond_to?(:schedule) && (
          schedule.start_date <= Date.today+2.days || (schedule.previous_changes.has_key?(:start_date) && !schedule.previous_changes[:start_date].try(:first).blank? && schedule.previous_changes[:start_date].try(:first).try(:to_date) <= Date.today+2.days)
        )
      ) || (respond_to?(:initial_time) && (initial_time.to_date <= Date.today + 2.days || (!initial_time_was.blank? && initial_time_was.to_date <= Date.today + 2.days)))
    )
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
          WHERE ac.allocation_tag_id = #{at} AND (evaluative = 't' OR frequency = 't') AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM discussions
          JOIN schedules ON schedules.id=discussions.schedule_id
          JOIN academic_allocations ac ON ac.academic_tool_id = discussions.id AND academic_tool_type = 'Discussion'
          WHERE ac.allocation_tag_id = #{at} AND (evaluative = 't' OR frequency = 't') AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM chat_rooms
          JOIN schedules on schedules.id = chat_rooms.schedule_id
          JOIN academic_allocations ac ON ac.academic_tool_id = chat_rooms.id AND academic_tool_type = 'ChatRoom'
          WHERE ac.allocation_tag_id = #{at} AND (evaluative = 't' OR frequency = 't') AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM exams
          JOIN schedules on schedules.id = exams.schedule_id
          JOIN academic_allocations ac ON ac.academic_tool_id = exams.id AND academic_tool_type = 'Exam'
          WHERE ac.allocation_tag_id = #{at} AND (evaluative = 't' OR frequency = 't') AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION

          SELECT MAX(schedules.end_date) AS ed, ac.id AS ac_id
          FROM schedule_events
          JOIN schedules on schedules.id = schedule_events.schedule_id
          JOIN academic_allocations ac ON ac.academic_tool_id = schedule_events.id AND academic_tool_type = 'ScheduleEvent'
          WHERE ac.allocation_tag_id = #{at} AND (evaluative = 't' OR frequency = 't') AND final_exam = 'f' #{where}
          GROUP BY ac.id

          UNION

          SELECT MAX((initial_time + (interval '1 mins')*duration)::date) AS ed, ac.id AS ac_id
          FROM webconferences
          JOIN academic_allocations ac ON ac.academic_tool_id = webconferences.id AND academic_tool_type = 'Webconference'
          WHERE ac.allocation_tag_id = #{at} AND (evaluative = 't' OR frequency = 't') AND final_exam = 'f' #{where}
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
  rescue
    {date: nil, ac_id: nil}
  end

  def self.send_email(object, acs, verify_type='delete')
    object.send_email(verify_type, acs)
  end

  def send_email(verify_type='delete', acs=nil)
    begin
      ats = (acs.nil? ? academic_allocations : acs).map(&:allocation_tag_id).flatten.uniq
      ats = AllocationTag.where(id: ats).joins('LEFT JOIN groups ON groups.id = allocation_tags.group_id').where("group_id IS NULL OR groups.status = 't'").map(&:id).uniq
    rescue
      ats = [acs.allocation_tag]
    end
    Thread.new do
      ActiveRecord::Base.connection
        ats.each do |at|
          emails = User.with_access_on('receive_academic_tool_notification','emails',ats, true).map(&:email).compact.uniq

          info = AllocationTag.find(ats.first).no_group_info
          groups = (ats.size > 1 ? ' - ' + Group.joins(:allocation_tag).where(allocation_tags: {id: ats}).map(&:code).join(', ') : '')
          unless emails.empty?
            if ((verify_type == 'delete') || (respond_to?(:status_changed?) && (status_changed? && !status)))
              if (verify_can_destroy)
                unless self.class.to_s == 'Notification'
                 template_mail = delete_msg_template(info + groups)
-                subject = I18n.t('editions.mail.subject_delete')
                end
              end
            elsif !verify_type || (respond_to?(:status_changed?) && status_changed? && status)
              template_mail = new_msg_template(info + groups)
              subject = I18n.t('editions.mail.subject_new')
            elsif verify_type
              unless self.class.to_s == 'Notification'
                template_mail = update_msg_template(info + groups)
                subject =  I18n.t('editions.mail.subject_update')
              end
            end
            Job.send_mass_email(emails, subject, template_mail) unless subject.blank?
          end
        end
      ActiveRecord::Base.connection.close
    end
  end

  def verify_can_destroy
    return true if !respond_to?(:can_destroy?)
    result = can_destroy?
    return true if result.blank?
    return result
  rescue
    return false
  end

  private

    def new_msg_template(info)
      if respond_to?(:initial_time)
        start_date = initial_time.strftime("%d/%m/%Y %H:%M")
        end_date = (initial_time + (duration * 60)).strftime("%d/%m/%Y %H:%M")
      elsif respond_to?(:schedule)
        start_date = schedule.start_date
        end_date = schedule.end_date
      end

      hours = (respond_to?(:start_hour) && !start_hour.blank?) ? "de #{start_hour} às #{end_hour}" : ""

      unless start_date.blank?
        %{
          Informamos que um #{I18n.t("activerecord.models.#{self.class.to_s.tableize.singularize}")} de nome #{respond_to?(:title) ? self.title : self.name} de #{info} foi criado(a) com o período de #{start_date} à #{end_date} #{hours}.
          <br/><br/><br/>
          Não responda esta mensagem. Este é um email automático do Solar 2.0.
        }
      end
    end

    def update_msg_template(info)
      if respond_to?(:initial_time)
        changes1 = [initial_time_was, initial_time].compact
        start_date = [changes1.first.strftime("%d/%m/%Y %H:%M"), changes1.last.strftime("%d/%m/%Y %H:%M")]

        changes2 = [duration_was, duration].compact
        end_date = [(changes1.first + (changes2.first * 60)).strftime("%d/%m/%Y %H:%M"), (changes1.last + (changes2.last * 60)).strftime("%d/%m/%Y %H:%M")]
      elsif respond_to?(:schedule)
        changes = schedule.previous_changes[:start_date].compact rescue [schedule.start_date]
        start_date = [changes.first, changes.last]

        changes = schedule.previous_changes[:end_date].compact rescue [schedule.end_date]
        end_date = [changes.first, changes.last]
      end

      dates = if start_date.size == 1 && end_date.size == 1
        " para #{start_date.last} à #{end_date.last}"
      else
        " de #{start_date.first} à #{end_date.first} para #{start_date.last} à #{end_date.last}"
      end

      if respond_to?(:start_hour)
        changes1 = [start_hour_was, start_hour].compact.reject { |c| c.empty? }
        start_hour = [changes1.first, changes1.last]

        changes2 = [end_hour_was, end_hour].compact.reject { |c| c.empty? }
        end_hour = [changes2.first, changes2.last]

        hours = if changes1.any? || changes2.any?
          if start_hour_was.blank?
            ". O horário foi definido para #{start_hour.last} às #{end_hour.last}"
          elsif start_hour.blank?
            ". O horário de #{start_hour.first} às #{end_hour.first} foi removido"
          elsif !start_hour.blank?
            ". O horário foi alterado de #{start_hour.first} às #{end_hour.first} para #{start_hour.last} às #{end_hour.last}"
          else
            ". O horário se manteve de #{start_hour.first} às #{end_hour.first}"
          end
        else
          ''
        end
      end

      unless start_date.blank?
        %{
          Informamos que a atividade (#{I18n.t("activerecord.models.#{self.class.to_s.tableize.singularize}")}) #{respond_to?(:title) ? self.title : self.name} de #{info} teve seu período alterado #{dates} #{hours}.
          <br/><br/><br/>
          Não responda esta mensagem. Este é um email automático do Solar 2.0.
        }
      end
    end

    def delete_msg_template(info)
      %{
        Informamos que a atividade (#{I18n.t("activerecord.models.#{self.class.to_s.tableize.singularize}")}) #{respond_to?(:title) ? self.title : self.name} de #{info} foi removida.
        <br/><br/><br/>
          Não responda esta mensagem. Este é um email automático do Solar 2.0.
      }
    end


    def define_academic_associations

      unless allocation_tag_ids_associations.blank?
        academic_allocations.create allocation_tag_ids_associations.map {|at| { allocation_tag_id: at }} unless self.class.to_s == 'ChatRoom'
      else
        academic_allocations.create
      end
    end

    def set_schedule
      self.schedule.check_end_date = true # mandatory final date
      if new_record?
        self.schedule.verify_offer_ats = allocation_tag_ids_associations
      else
        self.schedule.verify_offer_ats = allocation_tags.map(&:id).flatten
      end
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
