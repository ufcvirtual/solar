class SavsController < ApplicationController

  before_filter :prepare_for_pagination
  
  def index
    return if SavConfig::CONFIG.nil?
    return unless active_tab[:url][:allocation_tag_id]

    at   = AllocationTag.find(active_tab[:url][:allocation_tag_id])
    allocation_tags_ids = at.related
    group = at.group
    savs = Sav.current_savs({ allocation_tags_ids: allocation_tags_ids, group_id: group.id })

    if savs.any?
      user_profiles = current_user.profiles.where('(allocations.allocation_tag_id IN (?))', allocation_tags_ids).pluck(:id)
      savs = savs.where('profile_id IN (?) OR profile_id IS NULL', user_profiles).pluck(:id)

      if savs.any?
        client   = Savon.client wsdl: SavConfig::WSDL
        response = client.call SavConfig::METHOD.to_sym, message: { "name" => encrypt(current_user.name), "cpf" => encrypt(current_user.cpf), "group_id" => encrypt(group.try(:id).to_s), "offer_id" => encrypt(group.offer.try(:id).to_s), "course_id" => encrypt(group.course.try(:id).to_s), "curriculum_unit_id" => encrypt(group.curriculum_unit.try(:id).to_s), "curriculum_unit_type_id"=> encrypt(group.curriculum_unit_type.try(:id).to_s), "semester_id" => encrypt(group.semester.try(:id).to_s), "perfis_id" => { "string" => user_profiles.map{ |id| encrypt(id.to_s) }.flatten } }
        response_url = response.as_json[:url_questionario_response][:url_questionario_result]

        sav_url = URI.parse(response_url).path rescue nil
        (sav_url.nil? ? (Rails.logger.info "[SAV] [ERROR] message: #{response_url}" ) : (sav_url = response_url))
      end
    end

    render json: {url: (sav_url.include?('http') ? sav_url : 'http://'+sav_url) || ''}
  end

private 

  def encrypt(value)
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
    cipher.encrypt
    cipher.iv, cipher.key  = SavConfig::IV, SavConfig::KEY
    Base64.encode64(cipher.update(value) + cipher.final).gsub("\n",'').html_safe
  end

end
