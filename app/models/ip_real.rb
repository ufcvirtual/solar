class IpReal < ActiveRecord::Base
  require "resolv"

  belongs_to :exam
  belongs_to :assignment

  validate :validate_ip_v4, unless: 'ip_v4.blank?'
  validate :validade_ip_v6, unless: 'ip_v6.blank?'

  validate :can_create?, on: :create, unless: 'parent.blank? || !merge.nil?'
  validate :can_change?, on: :update, if: 'merge.nil?'
  before_destroy :can_destroy_callback?, if: 'parent.controlled'

  attr_accessor :merge

  def validate_ip_v4
    errors.add(:ip_v4, I18n.t(:ip, scope: [:ip_reals, :errors])) unless Resolv::IPv4::Regex =~ ip_v4
  end

  def validade_ip_v6
    errors.add(:ip_v6, I18n.t(:ip, scope: [:ip_reals, :errors])) unless Resolv::IPv6::Regex =~ ip_v6
  end

  def self.network_ips_permited(id, user_ip, obj)
    IpReal.where("(#{obj.to_s}_id = ? AND ip_v4 = ?) OR (#{obj.to_s}_id = ? AND ip_v6 = ?)", id, user_ip, id, user_ip)
  end

  def self.verify_ip(id, user_ip, obj, controlled)
    (controlled && self.network_ips_permited(id, user_ip, obj).blank?)
  end

  def can_create?
    errors.add(:ip_v4, I18n.t('ip_control.errors.date_end')) if !ip_v4.blank? && parent.ended? && (!parent.respond_to?(:status) || parent.status)
    errors.add(:ip_v6, I18n.t('ip_control.errors.date_end')) if !ip_v6.blank? && parent.ended? && (!parent.respond_to?(:status) || parent.status)
  end

  def can_change?
    errors.add(:ip_v4, I18n.t('ip_control.errors.date')) if !ip_v4.blank? && parent.started? && ip_v4_changed? && (!parent.respond_to?(:status) || parent.status)
    errors.add(:ip_v6, I18n.t('ip_control.errors.date')) if !ip_v6.blank? && parent.started? && ip_v6_changed? && (!parent.respond_to?(:status) || parent.status)
  end

  def can_destroy?
    if ((!ip_v4_was.blank? || !ip_v6_was.blank?) && (parent.started? && (!parent.respond_to?(:status) || parent.status)))
      return false
    end
    return true
  end

  def can_destroy_callback?
    if parent.ip_reals.size == 1
      raise 'controlled'
    end
    raise 'controlled_date' unless can_destroy?
  end

  def parent
    (exam || assignment)
  end
end
