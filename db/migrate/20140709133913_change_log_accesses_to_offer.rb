class ChangeLogAccessesToOffer < ActiveRecord::Migration
  
  def up

    User.all.each do |user|
      
      user_offers = AllocationTag.where(id: user.allocations.map(&:allocation_tag_id).compact).map(&:offers).flatten.compact
      logs        = LogAccess.where(user_id: user.id, log_type: LogAccess::TYPE[:offer_access]).delete_if{|log| log.allocation_tag_id.nil?}
      logs.each do |log|
        
        uc = log.allocation_tag.curriculum_unit

        unless uc.nil?
          uc_offers = uc.offers
          offers    = (user_offers & uc_offers)
          offers.each do |offer|
            
            if offer == offers.first # se for primeira oferta, substitui
              log.update_attribute(:allocation_tag_id, offer.allocation_tag.id)
            else # se tiver mais de uma e não for a primeira, cria novos logs
              LogAccess.offer(user_id: user.id, allocation_tag_id: offer.allocation_tag.id, ip: log.ip, created_at: log.created_at)
            end

          end # offers
        end # unless uc nil
      
      end # logs

    end # users

  end

  def down

    LogAccess.where(log_type: LogAccess::TYPE[:offer_access]).delete_if{|log| log.allocation_tag_id.nil?}.each do |log|
      offer = log.allocation_tag.offer

      unless offer.nil?
        uc_at = offer.curriculum_unit.allocation_tag.id

        if LogAccess.where(log_type: LogAccess::TYPE[:offer_access], user_id: log.user_id, ip: log.ip, created_at: log.created_at, allocation_tag_id: uc_at).empty? # se não existir o mesmo log pra mesma uc
          log.update_attribute(:allocation_tag_id, uc_at)
        else
          log.delete
        end
      end
    end
    
  end

end
