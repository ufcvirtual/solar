object @discussion

attributes :id, :name, :description, :start_date, :end_date

node(:status) { |discussion| discussion.status(current_user)}

node(:last_post_date) { |discussion| discussion.last_post_date(@group.allocation_tag.id) }
