collection @posts

@posts.each do |post|
  extends 'posts/show', locals: {post: post}
end 
