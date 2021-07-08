module V1::FileDownload
	extend Grape::API::Helpers
  def send_file(filepath, filename, disposition = 'inline')
    raise ActiveRecord::RecordNotFound unless File.exist?(filepath)

    env['api.format'] = :binary
    content_type MIME::Types.type_for(filepath)[0].to_s
    # header "Content-Disposition", "#{disposition}; filename*=UTF-8''#{Digest::MD5.hexdigest(filepath)}"
    header "Content-Disposition", "#{disposition}; filename*=UTF-8''#{filename}"

    File.open(filepath).read
  end

end
