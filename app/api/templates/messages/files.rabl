collection @files

@files.each do |file|
  attributes :attachment

  node :url do |f|
    api_download_messages_url(file_id: f.id)
  end
end 
