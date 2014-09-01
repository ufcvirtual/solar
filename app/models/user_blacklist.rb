class UserBlacklist < ActiveRecord::Base

  include PersonCpf

  validates :name, presence: true

  attr_accessible :cpf, :name

end
