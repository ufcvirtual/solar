module AccessControlHelper

  def return_type(extension)
    case extension
    when "jpg", "jpeg"
      type = 'image/jpeg'
    when "gif"
      type = 'image/gif'
    when "png"
      type = 'image/png'
    when "swf"
      type = 'application/x-shockwave-flash'
    when "pdf"
      type = 'application/pdf'
    when "htm", "html"
      type = 'text/html; charset=utf-8'
    when "doc"
      type = 'application/msword'
    when "docx"
      type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when "ppt"
      type = 'application/vnd.ms-powerpoint'
    when "pptx"
      type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    when "txt"
      type = 'text/plain'
    else
      type = "application/octet-stream"
    end
    return type
  end

end