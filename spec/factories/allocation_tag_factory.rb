Factory.define :allocation_tag do |allocation_tag|
  include ActionDispatch::TestProcess
  allocation_tag.groups_id 1
  allocation_tag.offers_id nil
  allocation_tag.curriculum_units_id nil
  allocation_tag.courses_id nil
end