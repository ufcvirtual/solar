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
end
