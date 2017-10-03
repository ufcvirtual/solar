object @post

attributes :id, :parent_id, :profile_id, :discussion_id, :user_id, :level, :content, :created_at, :children_count, :draft

node(:created_at) { |post| post.created_at.iso8601(5) }
node(:user_nick) { |post| post.user.nick }

child files: :files do |files|
  extends 'posts/files', locals: {files: files}
end
