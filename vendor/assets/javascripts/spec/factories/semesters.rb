# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :semester do
    name "MyString"
    offer_schedule_id nil
    enrollment_schedule_id nil
  end
end
