collection @files

@files.each do |file|
  attributes id: :id, attachment_file_name: :name, attachment_content_type: :content_type, attachment_updated_at: :updated_at, attachment_file_size: :size

  node :url do |f|
    api_download_post_post_file_url(post_id: f.discussion_post_id, id: f.id)
  end
end 
