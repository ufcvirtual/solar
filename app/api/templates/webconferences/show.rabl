object @webconference

attributes :id, :title, :initial_time, :situation, :duration, :evaluative, :frequency
attributes :situation => :finished_and_processed

node (:access_url) { |web| "/api/v1/webconferences/#{@group_id}/access/#{web.id}" }

node (:recordings_url) { |web| "/api/v1/webconferences/#{@group_id}/recordings/#{web.id}" }

if @is_student
  attributes :grade, :working_hours

  child :comments_by_user => :comments do
    attributes :id, :comment, :updated_at
    node(:user) {|comment|  comment.user.name}
  end
end
