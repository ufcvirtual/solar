# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :log_action do
    user nil
    description "MyString"
    tool nil
    logtype 1
    ip "MyString"
  end
end
