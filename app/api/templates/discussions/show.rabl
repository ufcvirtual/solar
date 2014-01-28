object @discussion

attributes :id, :name, :description, :last_post_date, :status

glue @discussion.schedule do
  attributes :start_date, :end_date
end
