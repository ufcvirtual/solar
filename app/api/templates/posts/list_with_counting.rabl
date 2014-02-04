node do
  { 
    newer: @discussion.count_posts_after_period(@period), 
    older: @discussion.count_posts_before_period(@period), 
    posts: partial("posts/list", object: @posts) 
  }
end


