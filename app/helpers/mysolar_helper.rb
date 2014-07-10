module MysolarHelper

  ##
  # Retorna as ofertas que o usuário atual está relacionado e que são correntes na seguinte ordenação:
  # Maior quantidade de acessos nas últimas 3 semanas > Ter turmas > Nome ASC
  ##
  def load_curriculum_unit_data
    currents = Offer.currents(Date.today.year, true)
    u_offers = AllocationTag.where(id: current_user.allocations.where(status: Allocation_Activated).uniq.pluck(:allocation_tag_id)).map(&:offers).flatten.compact
    offers   = (currents & u_offers)

    allocations_info = offers.collect{ |offer| 
        {
          id: offer.id,
          info: AllocationTag.allocation_tag_details(offer.allocation_tag, false, false, true),
          info_code: AllocationTag.allocation_tag_details(offer.allocation_tag, false, true, true),
          at: offer.allocation_tag.id,
          name: offer.curriculum_unit.try(:name) || offer.course.try(:name),
          has_groups: not(offer.groups.empty?)
        }
    }.flatten

    allocations_info.sort_by! do |allocation|
      allocation[:info]
      allocation[:has_groups]
      -(LogAccess.count(:id, conditions: {log_type: LogAccess::TYPE[:offer_access], user_id: current_user.id,
        allocation_tag_id: allocation[:at], created_at: 3.week.ago..Time.now}))
    end

    return allocations_info
  end

end
