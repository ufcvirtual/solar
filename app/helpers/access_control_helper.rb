module AccessControlHelper

  def return_type(extension)
    case extension
      when "jpg", "jpeg"
        'image/jpeg'
      when "gif"
        'image/gif'
      when "png"
        'image/png'
      when "swf"
        'application/x-shockwave-flash'
      when "pdf"
        'application/pdf'
      when "htm", "html"
        'text/html; charset=utf-8'
      when "doc"
        'application/msword'
      when "docx"
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      when "ppt"
        'application/vnd.ms-powerpoint'
      when "pptx"
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      when "txt"
        'text/plain'
      else
        "application/octet-stream"
    end
  end

end
