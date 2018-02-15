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
    #cpf = Cpf.new(self.cpf)
    errors.add(:cpf, I18n.t(:new_user_msg_cpf_error)) if not(cpf.nil?) and not(PersonCpf.valid_cpf?(cpf))
  end


  def self.valid_cpf?(cpf=nil)
    return false if cpf.nil?
   
    winvalidos = %w{12345678909 11111111111 22222222222 33333333333 44444444444 55555555555 66666666666 77777777777 88888888888 99999999999 00000000000}
    wvalor = cpf.scan /[0-9]/
    if wvalor.length == 11
      unless winvalidos.member?(wvalor.join)
        wvalor = wvalor.collect{|x| x.to_i}
        wsoma = 10*wvalor[0]+9*wvalor[1]+8*wvalor[2]+7*wvalor[3]+6*wvalor[4]+5*wvalor[5]+4*wvalor[6]+3*wvalor[7]+2*wvalor[8]
        wsoma = wsoma - (11 * (wsoma/11))
        wresult1 = (wsoma == 0 or wsoma == 1) ? 0 : 11 - wsoma
        if wresult1 == wvalor[9]
          wsoma = wvalor[0]*11+wvalor[1]*10+wvalor[2]*9+wvalor[3]*8+wvalor[4]*7+wvalor[5]*6+wvalor[6]*5+wvalor[7]*4+wvalor[8]*3+wvalor[9]*2
          wsoma = wsoma - (11 * (wsoma/11))
          wresult2 = (wsoma == 0 or wsoma == 1) ? 0 : 11 - wsoma
          return true if wresult2 == wvalor[10] # CPF validado
        end
      end
    end
    return false # CPF invalidado
  end

  module ClassMethods

    def cpf_without_mask(cpf)
      cpf.gsub(/[.-]/, '') rescue nil
    end

  end

end
