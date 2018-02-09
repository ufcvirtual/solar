module AutomaticFrequencyHelper

  def set_automatic_frequency(activity)
    automatic_frequency("set_frequency", activity)
  end

  def remove_automatic_frequency(activity)
    automatic_frequency("remove_frequency", activity)
  end

  private

    def automatic_frequency(type, activity)
      unless activity.nil? || activity.academic_allocation_user_id.nil?
        academic_allocation_user = activity.class.to_s == "AcademicAllocationUser" ? activity : AcademicAllocationUser.find(activity.academic_allocation_user_id)
        academic_allocation = AcademicAllocation.find(academic_allocation_user.academic_allocation_id)

        if academic_allocation.frequency_automatic && !academic_allocation_user.evaluated_by_responsible

          if activity.class.to_s != "AcademicAllocationUser"
            query = { academic_allocation_user_id: activity.academic_allocation_user_id }
            query.merge!( {draft: false} ) if activity.class.to_s == "Post"
            activities = activity.class.where(query)
          end

          if type == "set_frequency"
            if activity.class.to_s == "Post" && !activity.draft
              academic_allocation_user.working_hours = academic_allocation.max_working_hours
            else
              academic_allocation_user.working_hours = academic_allocation.max_working_hours
            end
          elsif type == "remove_frequency" && activities.size < 1
            academic_allocation_user.working_hours = nil
          end

          academic_allocation_user.save
        end
      end
    end

end
