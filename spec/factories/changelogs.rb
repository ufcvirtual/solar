# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :changelog do
    type ""
    description "MyText"
    date "2019-02-12"
    author "MyString"
    completed false
  end
end
