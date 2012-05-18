FactoryGirl.define do
  factory :lesson do
    name  "aula"
    address "http://www.ufc.br"
    type_lesson 1
    order 1
    status 1
    "start" "2011-02-01"
    "end"   "2011-12-01"
    allocation_tag_id 1
  end
end
