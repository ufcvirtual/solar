# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :curriculum_unit do
    name "MyString"
    code "MyString"
    resume "MyText"
    syllabus "MyText"
    passing_grade 1.5
    objectives "MyString"
    prerequisites ""
  end
end
