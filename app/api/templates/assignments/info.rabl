collection @acus, :root => :assignments, :object_root => :assignment

node do |acu|
  { 
    id: acu.academic_allocation.academic_tool.id,
    assignment_name: acu.academic_allocation.academic_tool.name,
    user_id: acu.user.nil? ? @student.id : acu.user.id,
    user_name: acu.user.nil? ? @student.name : acu.user.name,
    grade: acu.info[:grade] || 0,
    working_hours: acu.info[:working_hours] || 0,
    date_start: acu.academic_allocation.academic_tool.schedule.start_date,
    date_end: acu.academic_allocation.academic_tool.schedule.end_date,
    situation: acu.academic_allocation.academic_tool.info((acu.user.nil? ? @student.id : acu.user.id), acu.allocation_tag.id)[:situation]
  }
end

child :comments do
  node do |c|
    {
      by: c.user.nick,
      comment: c.comment,
      files: c.files.map{|f| download_comments_url(file_id: f.id)}
    }
  end
end

child :assignment_files => :sent_files do
  node do |f|
    {
      file_name: f.attachment_file_name,
      url: download_assignment_files_url(id: f.id)
    }
  end
end
 
@acus.each do |acu|  
  node :enunciation_files do |acu|
    acu.academic_allocation.academic_tool.enunciation_files.map do |file|
      {
        file_name: file.attachment_file_name,
        url: download_assignments_url(id: file.id)
      }
    end
  end
end

@acus.each do |acu|  
  node :webconferences do |acu|
    acu.assignment_webconferences.map do |aw|
      {
        title: aw.title,
        access_url: access_assignment_webconference_url(aw.id, student_id: acu.user.id),
        recordings: aw.recordings.map{|record| Bbb.get_recording_url(record, 'presentation')}
      }
    end
  end
end

node do |acu|
  {
    assignment_type: acu.academic_allocation.academic_tool.type_assignment == 0 ? :Individual : :Group,
    group_name: acu.group_assignment.nil? ? nil : acu.group_assignment.group_name,
    group_participans_ids: acu.group_assignment.nil? ? nil : acu.group_assignment.users.map{|user| user.id}
  }
end