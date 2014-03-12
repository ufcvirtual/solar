collection @users

attributes name: :nome, cpf: :cpf, email: :email, birthdate: :dtNascimento, gender: :sexo, telephone: :telefone, cell_phone: :celular, address_number: :numero, zipcode: :cep, address_neighborhood: :bairro, state: :estado, city: :municipio

node :endereco do |user| 
  [user.address, user.address_complement].compact.join(", ")
end
