node do
  {
    newer: @discussion.count_posts_after_period(@period, @ats),
    older: @discussion.count_posts_before_period(@period, @ats),
    posts: partial("posts/list", object: @posts)
  }
end
