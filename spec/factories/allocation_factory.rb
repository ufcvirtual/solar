Factory.define :allocation do |allocation|
  include ActionDispatch::TestProcess
  allocation.users_id	1
  allocation.groups_id	1
  allocation.profiles_id	1
  allocation.status 1
end