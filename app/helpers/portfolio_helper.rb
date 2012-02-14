module PortfolioHelper

  # recupera o icone correspondente ao tipo de arquivo
  def icon_attachment(file)
    case File.extname(file)
      when '.pdf'
        'mimetypes/pdf.png'
      when '.doc', '.docx', '.odt'
        'mimetypes/document.png'
      when '.xls', '.xlsx', '.ods'
        'mimetypes/spreadsheet.png'
      when '.ppt', '.pptx', '.odp'
        'mimetypes/presentation.png'
      when '.txt'
        'mimetypes/text.png'
      when '.link'
        'mimetypes/url.png'
      when '.png', '.jpg', '.jpeg', '.bmp'
        'mimetypes/image.png'
      when '.mp3', '.wav', '.m4a', '.wav'
        'mimetypes/audio.png'
      when '.avi', '.mpg', '.mp4'
        'mimetypes/video.png'
      else
        'mimetypes/default.png'
    end
  end

end
