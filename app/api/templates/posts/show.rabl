object @post

attributes :id, :user_id, :content, :updated_at, :parent_id, :discussion_id, :profile_id

glue @post.user do
  attributes username: :user_nick
end
