class Usuario < ActiveRecord::Base
	require 'digest/sha1'

  def sha1(senha) 
    Digest::SHA1.hexdigest(senha)
  end
end
