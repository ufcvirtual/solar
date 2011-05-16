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

    # *** mesma query usada no controller lessons, so MUDA q no where tem o ID da LESSON ***
    # consulta aulas com acesso permitido
    query_lessons = "select * from (SELECT distinct at.id as id, at.offers_id as offerid, l.id as lessonid,
                           l.allocation_tags_id as alloctagid,
                           l.name, description, address, l.type_lesson, privacy, l.order, l.start, l.end
                      FROM lessons l
                      LEFT JOIN allocation_tags at ON l.allocation_tags_id = at.id
                    WHERE
                      status=#{Lesson_Approved} and l.start<=current_date and l.end>=current_date
                      and (at.offers_id in ( #{offers} )) 
                      and l.id=#{params[:id]}              -- filtra pela aula passada
                    ORDER BY L.order) as query_offer

                    UNION ALL

                    select * from (SELECT distinct at.id as id, at.offers_id as offerid, l.id as lessonid,
                           l.allocation_tags_id as alloctagid,
                           l.name, description, address, l.type_lesson, privacy, l.order, l.start, l.end
                      FROM lessons l
                      LEFT JOIN allocation_tags at ON l.allocation_tags_id = at.id
                    WHERE
                      status=#{Lesson_Approved} and l.start<=current_date and l.end>=current_date
                      and (at.groups_id in ( #{groups} )) 
                      and l.id=#{params[:id]}             -- filtra pela aula passada
                    ORDER BY L.order) as query_group"
    
    permited_lessons = Lesson.find_by_sql(query_lessons)
    
    # se tem aula passada em disciplina aberta, pode acessar
    if (permited_lessons.length>0)
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

        # path do arquivo da aula
        send_file("#{Rails.root}/media/lessons/#{params[:id]}/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
    end
    
  end

end
