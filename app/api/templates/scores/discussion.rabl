object @struct

child :posts => :posts do
  attributes :content, :created_at
end

child :comments do
  node do |c|
    {
      comment: c.comment,
      by: c.user.name
    }
  end
end

