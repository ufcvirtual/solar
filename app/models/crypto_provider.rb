class CryptoProvider

  # Senha encriptada com sha1
  def self.encrypt(*tokens)
	#criptografa so a senha, sem usar salt - precisa bater com a senha pre-existente
	cripto = Digest::SHA1.hexdigest(tokens[0])
  end

  # Verifica se senha gravada confere com senha entrada pelo usuario
  def self.matches?(crypted, *tokens)
	Digest::SHA1.hexdigest(tokens[0]) == crypted
  end

end
