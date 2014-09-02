class UserBlacklist < ActiveRecord::Base

  include PersonCpf

  belongs_to :user

  validates :name, presence: true

  attr_accessible :cpf, :name, :user_id

  def self.search(text)
    text = [URI.unescape(text).split(' ').compact.join(":*&"), ":*"].join
    where("to_tsvector('simple', unaccent(cpf || ' ' || name)) @@ to_tsquery('simple', unaccent(?))", self.cpf_without_mask(text))
  end

end
