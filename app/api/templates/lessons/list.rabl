collection @lessons_modules

attributes :id, :name, :description, :order, :is_default

@lessons_modules.each do |lm|
  node :lessons do |lm|
    lm.lessons_to_open(current_user, list = true).map do |lesson|
      schedule = lesson.schedule
      {
        id: lesson.id,
        order: lesson.order,
        status: lesson.status,
        type: lesson.type_info,
        content_type: lesson.content_type,
        name: lesson.name,
        url: (lesson.is_link? ? lesson.link_path(api: true) : "/api/v1/groups/#{@group_id}/lessons/#{lesson.id}/#{lesson.address}"),
        start_date: schedule.start_date,
        end_date: schedule.end_date
      }
    end
  end

end
