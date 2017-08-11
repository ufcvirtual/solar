collection @files

@files.each do |file|
  attributes attachment: :attachment

  node :url do |f|
    api_download_message_file_url(message_id: f.message_id, id: f.id)
  end
end 
