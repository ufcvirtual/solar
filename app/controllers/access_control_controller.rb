class AccessControlController < ApplicationController

  include LessonsHelper
  include MessagesHelper

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
    # verificar se usuario logado tem aula passada em na(s) disciplina(s) aberta(s)

    groups = ""
    offers = ""

    # pega valores de offer e group das abas abertas pra consultar aulas
    tabs = session[:opened_tabs]
    tabs.each do |key, value|
      if (!value["groups_id"].nil?)
        groups += "," unless groups==""
        groups += value["groups_id"]
      end
      if (!value["offers_id"].nil?)
        offers += "," unless offers==""
        offers += value["offers_id"]
      end
    end

    # ex de formato do campo address da tabela lessons:
    #     /media/lessons/7/migrations.pdf
    #     http://www.virtual.ufc.br

    # retorna aulas
    permited_lessons = return_lessons_to_open(offers, groups, params[:id])

    # se tem aula passada em disciplina aberta, pode acessar
    if (permited_lessons.length>0)
        type = return_type(params[:extension])

        # path do arquivo da aula
        send_file("#{Rails.root}/media/lessons/#{params[:id]}/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
    end
  end

  def message
    # verifica se usuario logado tem permissao no arquivo anexo passado - se eh remetente ou destinatario da mensagem do arquivo
    type = return_type(params[:extension])
    name_attachment = params[:file]

    # se esta no formato correto: id_filename
    if name_attachment.index("_")>0
      # identifica id do message_file
      id_message_file = name_attachment.slice(0..name_attachment.index("_")-1)

      message_file = MessageFile.find_by_id(id_message_file)
      unless message_file.nil?
        id_message = message_file.nil? ? "" : message_file.message_id

        if has_permission(id_message)
          # path do arquivo do anexo da mensagem
          send_file("#{Rails.root}/media/messages/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
        end
      end
    end
  end

  private

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
