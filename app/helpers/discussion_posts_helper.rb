module DiscussionPostsHelper

  def posted_today?(message_datetime)
    message_datetime === Date.today
  end

  def count_post_by_user_discussion(user_id, discussion_id, allocation_tag_id)
  	Post.count_post_unread_by_user(user_id, discussion_id, allocation_tag_id)
  end	
  
end
