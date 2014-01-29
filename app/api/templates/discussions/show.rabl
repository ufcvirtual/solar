object @discussion

attributes :id, :status, :name, :description, :last_post_date

glue @discussion.schedule do
  attributes :start_date, :end_date
end
