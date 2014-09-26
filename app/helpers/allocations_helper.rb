module AllocationsHelper

  def status_hash(enroll = true)
    { Allocation_Pending_Reactivate => t("allocations.status.pending_reactivate"),
      Allocation_Pending            => t("allocations.status.pending"),
      Allocation_Activated          => (enroll ? t("allocations.status.enrolled") : t("allocations.status.activated")),
      Allocation_Cancelled          => t("allocations.status.cancelled"),
      Allocation_Rejected           => t("allocations.status.rejected") }
  end

  def name_of(status, enroll = true)
    status_hash(enroll)[status]
  end

  ## Rtorna os perfis disponíveis para alocação de determinado usuário em uma lista de allocations_tags
  def profiles_available_for_allocation(user_id, allocation_tags_ids)
    profiles_allocated = Profile.joins(:allocations).where("allocation_tag_id IN (?) AND user_id = ?", allocation_tags_ids.split(" "), user_id)
    query = profiles_allocated.empty? ? '' : " AND id NOT IN (#{profiles_allocated.map(&:id).join(',')})"

    profiles_available = Profile.where("cast(types & #{Profile_Type_Class_Responsible} as boolean)" + query)
  end


  def status_hash_of_allocation(allocation_status)
    case allocation_status
      when Allocation_Pending, Allocation_Pending_Reactivate
        status_hash.select { |k,v| [allocation_status, Allocation_Activated, Allocation_Rejected].include?(k) }
      when Allocation_Activated
        status_hash.select { |k,v| [allocation_status, Allocation_Cancelled].include?(k) }
      when Allocation_Cancelled, Allocation_Rejected
        status_hash.select { |k,v| [allocation_status, Allocation_Activated].include?(k) }
    end
  end

end
