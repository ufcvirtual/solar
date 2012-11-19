module AllocationsHelper
  def status_hash
    { Allocation_Pending_Reactivate => t(:pending_reactivate, :scope => [:allocations, :status]),
      Allocation_Pending => t(:pending, :scope => [:allocations, :status]),
      Allocation_Activated => t(:activated, :scope => [:allocations, :status]),
      Allocation_Cancelled => t(:cancelled, :scope => [:allocations, :status]),
      Allocation_Rejected => t(:rejected, :scope => [:allocations, :status]) }
  end

  def name_of(status)
    status_hash[status]
  end

  def profiles_available_for_allocation(user_id, allocation_tag_id)
    profiles_allocated = Profile.find(:all,
      :joins => [:allocations], 
      :conditions => ["allocation_tag_id in (?) and user_id = (?)", allocation_tag_id, user_id])

    query = profiles_allocated.empty? ? '' : " and id not in (#{profiles_allocated.map(&:id).join(',')})"

    profiles_available = Profile.find(:all,
      :conditions => ["(types & #{Profile_Type_Class_Responsible})::boolean" + query] )
  end
end
