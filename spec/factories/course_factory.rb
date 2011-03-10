Factory.define :course do |course|
  include ActionDispatch::TestProcess
  course.name	"test"
  course.code	"tst1"
end