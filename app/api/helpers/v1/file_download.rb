module V1::FileDownload

  def send_file(filepath, filename)
    raise ActiveRecord::RecordNotFound unless File.exist?(filepath)

    content_type MIME::Types.type_for(filepath)[0].to_s
    env['api.format'] = :binary
    header "Content-Disposition", "attachment; filename*=UTF-8''#{Digest::MD5.hexdigest(URI.escape(filename))}"

    File.open(filepath).read
  end

end
