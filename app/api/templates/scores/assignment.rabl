object @acu

node do |acu|
  {
    grade: acu.grade,
    frequency: acu.working_hours
  }
end

child :assignment_files => :sent_files do
  node do |f|
    {
      file_name: f.attachment_file_name,
      file_size: format('%.2f KB', f.attachment_file_size/1024.0),
      file_sent_on: f.attachment_updated_at,
      url: download_assignment_files_url(id: f.id)
    }
  end
end

node :webconferences do |acu|
  acu.assignment_webconferences.map do |aw|
    {
      title: aw.title,
      status: aw.status,
      initial_time: aw.initial_time,
      duration: aw.initial_time + aw.duration.minutes,
      final_version:  aw.final,
      access_url: access_assignment_webconference_url(aw.id, student_id: acu.user.id),
      recordings: aw.recordings.map{|record| Bbb.get_recording_url(record, 'presentation')}
    }
  end
end

child :comments do
  node do |c|
    {
      by: c.user.nick,
      comment: c.comment
    }
  end
end
