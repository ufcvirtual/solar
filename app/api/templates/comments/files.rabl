collection @files

@files.each do |file|
  attributes id: :id, attachment_file_name: :name, attachment_content_type: :content_type, attachment_updated_at: :updated_at, attachment_file_size: :size

  node :url do |f|
    ("#{ENV['DNS_HOST']}" rescue '')+f.attachment.url
  end
end 
