collection @events

attributes :name, :start_hour, :end_hour, :place, :evaluative, :frequency


@events.each do |event|

  node(:type_event) { |eve| ScheduleEvent.type_name_event(eve.type_event.to_i)}
  node(:start_date) { |eve| eve.start_date.to_date}
  node(:end_date) { |eve| eve.end_date.to_date}
  node(:id) { |eve| eve.academic_tool_id}
  node(:academic_allocation_id) { |eve| eve.id}

  if @is_student
    node(:grade) { |eve| eve.grade }
    node(:working_hours) { |eve| eve.working_hours }
    node(:situation) { |eve| eve.situation}

    node(:comments) { |eve|
      AcademicAllocationUser.comments_by_user(eve.id, current_user.id).map do |c|
        {
          comment: c.comment,
          by: c.user.name,
          files: c.files.map{|f| download_comments_url(file_id: f.id)}
        }
      end
    }
  end

end