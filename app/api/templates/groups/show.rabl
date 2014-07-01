object @group

attributes :id, :code

glue @group.offer.semester do
  attributes name: :semester
end
