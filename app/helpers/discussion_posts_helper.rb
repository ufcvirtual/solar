module DiscussionPostsHelper

  def posted_today?(message_datetime)
    message_datetime === Date.today
  end

end
