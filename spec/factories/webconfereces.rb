# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :Webconference do
    user nil
    title "MyString"
    description "MyString"
    initial_time "2014-02-24 12:06:19"
    duration 1
  end
end
