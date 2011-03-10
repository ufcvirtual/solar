Factory.define :curriculum_unit do |curriculum_unit|
  include ActionDispatch::TestProcess
  curriculum_unit.name	"test"
  curriculum_unit.code	"tst1"
  curriculum_unit.category 1
end