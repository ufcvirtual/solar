object @discussion

attributes :id, :name, :description

node(:status) { |discussion| discussion.status(current_user)}

glue @discussion.schedule do
  attributes :start_date, :end_date
end

node(:last_post_date) { |discussion| discussion.last_post_date(@group.allocation_tag.id) }
