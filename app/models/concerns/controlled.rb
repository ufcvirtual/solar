require 'active_support/concern'

module Controlled
  extend ActiveSupport::Concern

  included do
    has_many :ip_reals, dependent: :delete_all

    validates_associated :ip_reals, if: 'controlled'
    validate :controlled_network_ip_validates, if: 'controlled' # mandatory at least one ip if the activity is controlled
    validate :can_change?, if: 'controlled_changed? && !new_record?'
    
    accepts_nested_attributes_for :ip_reals, allow_destroy: true, reject_if: lambda { |e| e[:ip_v4].blank? && e[:ip_v6].blank? }

    after_save :remove_ips, unless: 'controlled'
  end

  def controlled_network_ip_validates
    errors.add(:controlled, I18n.t("ip_control.errors.controlled")) if ip_reals.blank?
  end

  def remove_ips
    IpReal.where("#{self.class.to_s.tableize.singularize}_id" => id).destroy_all
  end

  def can_change?
    return true if (respond_to?(:status) && !status)
    errors.add(:controlled, I18n.t('ip_control.errors.date')) if started?
  end

end