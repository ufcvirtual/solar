collection @discussions

@discussions.each do |discussion|
  extends 'discussions/show', locals: { discussion: discussion }
end

node(:researcher) { @researcher }
node(:can_post) { @can_post }