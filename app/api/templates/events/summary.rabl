object @acu

node do |acu|
  {     
    user_name: acu.user.name,
    grade: acu.info[:grade] || 0,
    frequency: acu.info[:working_hours] || 0
  }
end

child :schedule_event_files => :sent_responsible_files do
  node do |f|
    {
      file_name: f.attachment_file_name,
      url: download_schedule_event_files_url(event_id: f.schedule_event.id, id: f.id)
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