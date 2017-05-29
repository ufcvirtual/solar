class IpReal < ActiveRecord::Base
  require "resolv"

  belongs_to :exam
  # has_many :ip_fakes, dependent: :destroy
  attr_accessible :id, :ip_v4, :ip_v6, :_destroy

  validate :validate_ip_v4, if: '!ip_v4.blank?'
  validate :validade_ip_v6, if: '!ip_v6.blank?'

  def validate_ip_v4
    errors.add(:ip_v4, I18n.t(:ip, scope: [:ip_reals, :errors])) unless Resolv::IPv4::Regex =~ ip_v4
  end

  def validade_ip_v6
    errors.add(:ip_v6, I18n.t(:ip, scope: [:ip_reals, :errors])) unless Resolv::IPv6::Regex =~ ip_v6
  end
end
