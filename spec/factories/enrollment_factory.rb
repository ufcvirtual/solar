Factory.define :enrollment do |enrollment|
  include ActionDispatch::TestProcess
  enrollment.offers_id	1
  enrollment.start "2011-02-01"
  enrollment.end "2011-02-01"
end