module V1::FileDownload

  def send_file(filepath, disposition = 'inline')
    raise ActiveRecord::RecordNotFound unless File.exist?(filepath)

    env['api.format'] = :binary
    content_type MIME::Types.type_for(filepath)[0].to_s
    header "Content-Disposition", "#{disposition}; filename*=UTF-8''#{Digest::MD5.hexdigest(filepath)}"

    File.open(filepath).read
  end

end
