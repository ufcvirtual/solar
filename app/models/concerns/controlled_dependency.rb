require 'active_support/concern'

module ControlledDependency
  extend ActiveSupport::Concern

  included do
    before_save :verify_ip, if: 'merge.nil? && !user_ip.blank?'
    before_destroy :verify_ip, if: 'merge.nil? && !user_ip.blank?'

    attr_accessor :user_ip, :merge
  end

  def verify_ip
    raise CanCan::AccessDenied if IpReal.verify_ip(tool.id, user_ip, tool.class.to_s.downcase.to_sym, tool.controlled)
  end

  def tool
    ac = academic_allocation_user.academic_allocation
    ac.academic_tool_type.constantize.find(ac.academic_tool_id)
  end

end