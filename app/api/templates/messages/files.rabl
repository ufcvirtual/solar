collection @files

@files.each do |file|
  attributes :attachment

  node :url do |f|
    download_file_messages_url(f.id)
  end
end 