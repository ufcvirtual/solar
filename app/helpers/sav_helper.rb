module SavHelper

  private
    def get_current_savs(allocation_tag_id)
      unless SavConfig::CONFIG.nil?
        at = AllocationTag.find(allocation_tag_id)
        allocation_tags_ids = at.related
        
        cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
        cipher.encrypt
        cipher.iv, cipher.key  = SavConfig::IV, SavConfig::KEY

        user_profiles = current_user.profiles.where("(allocations.allocation_tag_id IN (?) OR allocations.allocation_tag_id IS NULL)", allocation_tags_ids).pluck(:id)
        savs = Sav.current_savs(allocation_tags_ids).where("profile_id IN (?) OR profile_id IS NULL", user_profiles).pluck(:id).to_s.delete("[]")

        @_sav_url = (savs.empty? ? "" : [SavConfig::URL, Base64.encode64(cipher.update(
          SavConfig::PARAMS.gsub("user_cpf", current_user.cpf).gsub("user_name", current_user.name).gsub("profiles_ids", user_profiles.to_s.delete("[]"))
          .gsub("questionnaires_ids", savs).gsub("taggable_id", at.send(at.refer_to).try(:id).to_s)
        ) + cipher.final).gsub("\n",'')].join.html_safe)
      end
    end

end