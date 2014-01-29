object @post

attributes :id, :user_id, :content, :updated_at, :parent_id

glue @post.user do
  attributes :username
end
