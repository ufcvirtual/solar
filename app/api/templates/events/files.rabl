collection @schedule_event_files

attributes attachment_file_name: :file_name

@schedule_event_files.each do |file|

  node :url do |file|
    download_schedule_event_files_url(event_id: file.schedule_event.id, id: file.id)
  end

end 