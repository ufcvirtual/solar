FactoryGirl.define do
  factory :user do
    username "user_factory"
    email "user_factory@user.com"
    name "Usuario do Sistema"
    nick "Usuario do Sistema"
    cpf "518.138.453-60"
    birthdate "2005-03-02"
    gender "true"
    address "Lorem ipsum dolor sit amet."
    address_number "58"
    country "Brazil"
    state "CE"
    city "Fortaleza"
    institution "UFC"
    zipcode "60450170"
    password "123456"
    password_confirmation "123456"
  end
end
