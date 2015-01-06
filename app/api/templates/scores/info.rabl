# object false
#
# child @info[:assignments] do
#   attributes :name, :enunciation, :type_assignment
#
#   node do |a|
#     child a.info(current_user, @at) do |info|
#       node do
#       end
#     end
#   end
#
#   glue :schedule do
#     attributes :start_date, :end_date
#   end
#
#   # comments
#
# end
#
# child @info[:discussions] do |d|
#   attributes :name
#   node(:count_posts) { |d| d.posts_count } # desse usuario
# end
#
# child @info[:history_access] => :history_access do
#   attributes :log_type, :created_at
# end
