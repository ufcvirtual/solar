node do
  { 
    newer: @discussion.count_posts_after_period(@period, @group.allocation_tag.related), 
    older: @discussion.count_posts_before_period(@period, @group.allocation_tag.related),
    posts: partial("posts/list", object: @posts) 
  }
end


