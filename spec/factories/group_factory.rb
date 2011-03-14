Factory.define :group do |group|
  include ActionDispatch::TestProcess
  group.offers_id	1
  group.code "FOR"
  group.status "TRUE"
end