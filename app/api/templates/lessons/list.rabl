collection @lessons_modules

attributes :id, :name, :description, :order, :is_default

@lessons_modules.each do |lm|
  node :lessons do |lm|
    lm.lessons_to_open(current_user).map do |lesson|
      schedule = lesson.schedule
      {
        id: lesson.id,
        order: lesson.order,
        status: lesson.status,
        type: lesson.type_info,
        content_type: lesson.address.blank? ? '' : lesson.content_type,
        name: lesson.name,
        address: lesson.address,
        url: (lesson.is_link? ? lesson.link_path(api: true) : lesson.path(false, true)),
        start_date: schedule.start_date,
        end_date: schedule.end_date
      }
    end
  end

end
