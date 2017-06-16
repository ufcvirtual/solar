module IpRealHelper
  def verify_ip!(id, obj, controlled, response=:json)
    if IpReal.verify_ip(id, get_remote_ip, obj, controlled)
      Rails.logger.info "[ERROR] [APP] [#{Time.now}] [IP #{get_remote_ip} NOT ALLOWED AT #{obj} #{id}] [#{t('ip_control.errors.restrict')}]"
      case response
      when :json
        render json: { success: false, alert: t('ip_control.errors.restrict') }, status: :unprocessable_entity
      when :html
        redirect_to :back, alert: t('ip_control.errors.restrict')
      when :text
        render text: t('ip_control.errors.restrict')
      when :raise
        raise CanCan::AccessDenied
      when :boolean
        return false
      when :error_text
        raise t('ip_control.errors.restrict')
      when :error_text_min
        raise 'restrict'
      end

    end
    return true
  end

  def set_ip_user(variable_name = nil)
    if variable_name.blank?
      instance_variable_get("@#{params[:controller].singularize.downcase}").user_ip = get_remote_ip
    else
      instance_variable_get("@#{variable_name}").user_ip = get_remote_ip
    end
  end
end