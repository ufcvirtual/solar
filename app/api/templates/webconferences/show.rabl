object @webconference

attributes :id, :title, :initial_time, :duration, :situation, :evaluative, :frequency

node (:access_url) { |web| "/api/v1/webconferences/#{@group_id}/access/#{web.id}" }

node(:recordings) {|web| web.get_all_recordings_urls}
  

if @is_student
  attributes :grade, :working_hours

  child :comments_by_user => :comments do
    attributes :id, :comment, :updated_at
    node(:user) {|comment|  comment.user.name}
  end
end
