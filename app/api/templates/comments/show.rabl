object @comment

attributes :id, :comment, :updated_at

node(:user_name) { |comment| comment.user.nick }

child files: :files do |files|
  extends 'comments/files', locals: {files: files}
end
