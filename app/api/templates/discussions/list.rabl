collection @discussions

@discussions.each do |discussion|
  extends 'discussions/show', locals: {discussion: discussion}
end
