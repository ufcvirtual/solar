object @group

attributes :id, :code, :name

glue @group.offer.semester do
  attributes name: :semester
end
