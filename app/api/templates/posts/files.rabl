collection @files

@files.each do |file|
  attributes id: :id, 
    attachment_file_name: :file_name,
    attachment_content_type: :content_type, 
    attachment_updated_at: :updated_at
end 
