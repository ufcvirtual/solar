module FilesHelper

  def download_file(redirect_error, pathfile, filename = nil)
    if File.exist?(pathfile)
      send_file pathfile, :filename => filename
    else
      respond_to do |format|
        format.html { redirect_to redirect_error, :alert => t(:error_nonexistent_file) }
      end
    end
  end

end
