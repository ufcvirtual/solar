require 'active_support/concern'

module PersonCpf
  extend ActiveSupport::Concern

  included do
    before_validation :remove_mask_from_cpf

    validate :cpf_ok, unless: Proc.new { errors[:cpf].any? }
    validates :cpf, presence: true, uniqueness: true
  end

  def remove_mask_from_cpf
    self.cpf = self.class.cpf_without_mask(self.cpf)
  end

  def cpf_ok
    cpf = Cpf.new(self.cpf)
    errors.add(:cpf, I18n.t(:new_user_msg_cpf_error)) if not(cpf.nil?) and not(cpf.valido?)
  end

  module ClassMethods

    def cpf_without_mask(cpf)
      cpf.gsub(/[.-]/, '') rescue nil
    end

  end

end
