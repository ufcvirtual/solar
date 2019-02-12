object @posts_scores

child :posts => :posts do
  attributes :content, :created_at
end

node :comments do
  @posts_scores.all_user.comments.map do |c|
    {
      comment: c.comment,
      by: c.user.name
    }
  end
end

child :all_user => :scores do
  attributes :grade, :working_hours
end
