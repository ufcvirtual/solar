module SavHelper

  private
    def get_current_savs(group_id)
      unless SavConfig::CONFIG.nil?
        cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
        cipher.encrypt
        cipher.iv, cipher.key  = SavConfig::IV, SavConfig::KEY

        user_profiles = current_user.profiles.where('(allocations.allocation_tag_id IN (?) OR allocations.allocation_tag_id IS NULL)', AllocationTag.find_by_group_id(group_id).related).pluck(:id).to_s.delete("[]")
        savs = Sav.current_savs(group_id).to_s.delete("[]")
        @_sav_url = (savs.empty? ? "" : [SavConfig::URL, Base64.encode64(cipher.update(SavConfig::PARAMS.gsub("user_id", current_user.id.to_s).gsub("profiles_ids", user_profiles).gsub("savs_ids", savs)) + cipher.final).gsub("\n",'')].join.html_safe)
      end
    end

end