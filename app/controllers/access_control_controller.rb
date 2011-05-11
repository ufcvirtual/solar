class AccessControlController < ApplicationController

  before_filter :require_user

  # exibicao das imagens do usuario
  def photo
    user = User.find_by_id(params[:id])

    # verifica se o usuario requisitado existe
    head(:bad_request) and return if user.nil?

    # path da foto do usuario. style => medium | small
    path = user.photo.path(params[:style])

    # bad request(404) caso o arquivo nao seja encontrado
    head(:bad_request) and return unless File.exist?(path)

    # envia a imagem
    send_file(path, { :disposition => 'inline', :content_type => 'image' }) # content-type espcífico pra imagem
  end

  def lesson
    # FALTA REGRAS
    # verificar se usuario logado tem aula passada em alguma disciplina matriculada
    # 
    # ************

    case params[:extension]
    when "jpg", "jpeg"
      type = 'image/jpeg'
    when "gif"
      type = 'image/gif'
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
    
    #path do arquivo da aula
    send_file("#{Rails.root}/media/lessons/#{params[:id]}/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
  end

end
