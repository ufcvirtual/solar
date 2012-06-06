module AllocationsHelper

  def status_hash
    { Allocation_Pending_Reactivate => t(:allocation_status_pending),
      Allocation_Pending => t(:allocation_status_pending),
      Allocation_Activated => t(:allocation_status_activated),
      Allocation_Cancelled => t(:allocation_status_cancelled),
      Allocation_Rejected => t(:allocation_status_rejected) }
  end

  ## Nomeando status
  def name_of(status)
    status_hash[status]
  end

end
