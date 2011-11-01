module FilesHelper

  # download de arquivos
  def download_file(redirect_error, path_, filename_, prefix_ = nil)

    # verifica se o arquivo possui prefixo
    unless prefix_.nil?
      path_file = "#{path_}/#{prefix_}_#{filename_}"
    else
      path_file = "#{path_}/#{filename_}"
    end

    #Caso o caminho do arquivo todo tenha sido passado em 'path_', desconsidera
    #o resto e descobre o filename
    if (filename_ == '')
      path_file = path_
      pattern = /\//
      filename_ = path_file[path_file.rindex(pattern)+1..-1]
    end

    if File.exist?(path_file)
      send_file path_file, :filename => filename_
    else
      respond_to do |format|
        flash[:error] = t(:error_nonexistent_file)
        format.html { redirect_to(redirect_error) }
      end
    end

  end
  
end
