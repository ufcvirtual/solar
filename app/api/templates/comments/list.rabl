collection @comments

@comments.each do |comment|
  extends 'comments/show', locals: {comment: comment}
end 
