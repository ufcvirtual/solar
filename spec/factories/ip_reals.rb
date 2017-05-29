# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ip_real do
    ip_v4 "MyString"
    ip_v6 "MyString"
    exam nil
  end
end
