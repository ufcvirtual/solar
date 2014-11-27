module SavHelper

  def get_current_savs(allocation_tag_id)
    return if SavConfig::CONFIG.nil?

    at   = AllocationTag.find(allocation_tag_id)
    allocation_tags_ids = at.related
    savs = Sav.current_savs(allocation_tags_ids)

    if savs.any?
      user_profiles = current_user.profiles.where("(allocations.allocation_tag_id IN (?))", allocation_tags_ids).pluck(:id)
      savs = savs.where("profile_id IN (?) OR profile_id IS NULL", user_profiles).pluck(:id)

      if savs.any?
        client   = Savon.client wsdl: SavConfig::WSDL
        response = client.call SavConfig::METHOD.to_sym, message: {"name"=> encrypt(current_user.name), "cpf"=> encrypt(current_user.cpf), "group_id"=> encrypt(at.send(at.refer_to).try(:id).to_s), "perfis_id" => {"string" => user_profiles.map{|id| encrypt(id.to_s)}.flatten}}
        response_url = response.as_json[:url_questionario_response][:url_questionario_result]

        sav_url = URI.parse(response_url).path rescue nil
        (sav_url.nil? ? (Rails.logger.info "[SAV] [ERROR] message: #{response_url}" ) : (sav_url = response_url))
      end
    end

    user_session[:tabs][:opened][user_session[:tabs][:active]].merge!({sav_url: (sav_url || "")})
  end

  def encrypt(value)
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
    cipher.encrypt
    cipher.iv, cipher.key  = SavConfig::IV, SavConfig::KEY
    Base64.encode64(cipher.update(value) + cipher.final).gsub("\n",'').html_safe
  end
end
