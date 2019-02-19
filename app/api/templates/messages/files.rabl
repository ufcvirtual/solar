collection @files

@files.each do |file|
  attributes id: :id, attachment_file_name: :name, attachment_content_type: :content_type, attachment_file_size: :size, attachment_updated_at: :updated_at

  node :url do |f|
    api_download_messages_url(f.id)
  end
end