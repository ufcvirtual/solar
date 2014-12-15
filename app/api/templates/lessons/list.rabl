collection @lessons_modules

attributes :id, :name, :description, :order, :is_default

@lessons_modules.each do |lm|
  node :lesons do |lm|
    lm.lessons_to_open(current_user, list = true).map do |lesson|
      schedule = lesson.schedule
      {
        id: lesson.id,
        order: lesson.order,
        status: lesson.status,
        type: lesson.type_info,
        name: lesson.name,
        url: (lesson.is_link? ? lesson.link_path : "/api/v1/lessons/#{lesson.id}/download"),
        start_date: schedule.start_date,
        end_date: schedule.end_date
      }
    end
  end

end
