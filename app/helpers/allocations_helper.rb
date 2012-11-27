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

  ## Rtorna os perfis disponíveis para alocação de determinado usuário em uma lista de allocations_tags
  def profiles_available_for_allocation(user_id, allocation_tags_ids)
    profiles_allocated = Profile.all(:joins => [:allocations], 
      :conditions => ["allocation_tag_id IN (#{allocation_tags_ids}) AND user_id = (#{user_id})"])

    query = profiles_allocated.empty? ? '' : " AND id NOT IN (#{profiles_allocated.map(&:id).join(',')})"

    profiles_available = Profile.all( :conditions => ["(types & #{Profile_Type_Class_Responsible})::boolean" + query] )
  end

end
