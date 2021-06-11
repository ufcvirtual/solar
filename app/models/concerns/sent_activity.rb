require 'active_support/concern'

module SentActivity
  extend ActiveSupport::Concern

  included do
    after_save :update_acu, if: '(!respond_to?(:log_type) || log_type == LogAction::TYPE[:access_webconference]) && merge.nil?'
    after_destroy :update_acu, if: '(!respond_to?(:log_type) || log_type == LogAction::TYPE[:access_webconference]) && merge.nil?'

  end

  def update_acu
    return true if academic_allocation_user.blank?

    table_name = self.class.to_s.tableize
    empty_associations = case table_name
    when 'assignment_files'; (academic_allocation_user.assignment_files.empty? && academic_allocation_user.assignment_webconferences.empty?)
    when 'assignment_webconferences'; (academic_allocation_user.assignment_files.empty? && academic_allocation_user.assignment_webconferences.empty?)
    when 'posts'; academic_allocation_user.discussion_posts.where(draft: false).empty?
    else
      academic_allocation_user.send(table_name.to_sym).empty?
    end

    unless academic_allocation_user_id.blank?
      automatic = academic_allocation.frequency_automatic && !academic_allocation_user.evaluated_by_responsible

      if (academic_allocation_user.grade.blank? && academic_allocation_user.working_hours.blank?) || (!academic_allocation_user.working_hours.blank? && automatic)
        if empty_associations
          academic_allocation_user.status = AcademicAllocationUser::STATUS[:empty]
          academic_allocation_user.working_hours = nil if automatic
        else
          if automatic
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:evaluated]
            academic_allocation_user.working_hours = academic_allocation.max_working_hours
          else
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:sent]
          end
        end
      else
        academic_allocation_user.new_after_evaluation = true
      end
      academic_allocation_user.merge = merge if respond_to?(:merge)
      academic_allocation_user.save(validate: false)
      academic_allocation_user.recalculate_final_grade(academic_allocation_user.allocation_tag.id)
    end
  end

end
