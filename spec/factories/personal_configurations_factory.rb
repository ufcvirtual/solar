FactoryGirl.define do
  factory :personal_configuration do
    default_locale "pt_BR"
    mysolar_portlets "1&4|3|5&2"
    user_id 1
  end
end
