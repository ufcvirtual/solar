require 'active_support/concern'

module PersonCpf
  extend ActiveSupport::Concern

  included do

    # before save # remove points from cpf
    before_save :remove_mask_from_cpf


    validates :cpf, presence: true, uniqueness: true

    validate :cpf_ok, unless: Proc.new { errors[:cpf].any? }

    # attr_accessor :user_id
  end


  def remove_mask_from_cpf
    self.cpf = cpf_without_mask(self.cpf)
  end

  def cpf_ok
    cpf = Cpf.new(self.cpf)
    errors.add(:cpf, I18n.t(:new_user_msg_cpf_error)) if not(cpf.nil?) and not(cpf.valido?)
  end

  ## buscas por cpf aqui

  private

    def cpf_without_mask(cpf)
      cpf.gsub(/[.-]/, '') rescue nil
    end

end
