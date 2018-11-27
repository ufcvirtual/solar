collection @comments

attributes :id, :comment

@comments.each do |comment|
  node(:responsible) { comment.user.nick }
end
