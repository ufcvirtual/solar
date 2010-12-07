Factory.define :user do |user|
  include ActionDispatch::TestProcess
  user.login	"Who"
  user.email	"who@where.com"
  user.password	"whoknows"
  user.photo_file_name fixture_file_upload('public/images/rails.png', 'image/png')
end
