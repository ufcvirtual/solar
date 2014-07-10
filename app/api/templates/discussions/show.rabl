object @discussion

attributes :id, :status, :name, :description

glue @discussion.schedule do
  attributes :start_date, :end_date
end

node(:last_post_date) { |discussion| discussion.last_post_date(@group.allocation_tag.id) }
