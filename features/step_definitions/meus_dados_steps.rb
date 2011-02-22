Dado /^eu envio o arquivo "([^"]*)" no campo "([^"]*)"$/ do |file, file_field|
  attach_file(file_field, File.join(::Rails.root.to_s, 'features', 'upload_files', file))  
end


