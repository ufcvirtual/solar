class AccessControlController < ApplicationController

  include LessonsHelper
  include MessagesHelper
  include DiscussionPostsHelper

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
  
  def discussion
    name_attachment = params[:file]
    if name_attachment.index("_")>0
      id_file = name_attachment.slice(0..name_attachment.index("_")-1)
      file= PostFile.find(id_file)
      discussion= file.discussion_post.discussion
      
      # verificar se usuario logado tem forum na(s) disciplina(s) aberta(s)
      
      groups = ""
      offers = ""
      
      # pega valores de offer e group das abas abertas pra consultar foruns
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
      offers = -1 if offers.empty?
      groups = -1 if groups.empty?
      
      # se tem forum passado em disciplina aberta, pode acessar
      if (permitted_discussions(offers, groups, discussion.id).size>0)
        type = return_type(params[:extension])
        
        # path do arquivo anexo a postagem
        send_file("#{Rails.root}/media/discussions/post/#{name_attachment}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
      end
    end   
  end

  ##
  # Método que verifica se o usuário tem algum acesso ao arquivo que ele está tentando visualizar (na área individual)
  ##
  def portfolio_individual_area
    name_attachment = params[:file] 
    id_file = name_attachment.slice(0..name_attachment.index("_")-1)
    assignment = AssignmentFile.find(id_file).send_assignment.assignment

    # Verifica se o arquivo a ser acessado é dele ou do grupo dele
    student_individual_activity_or_part_of_the_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment.id, current_user.id, id_file)

    if student_individual_activity_or_part_of_the_group
      # path do arquivo anexo a postagem
      type = return_type(params[:extension])
      send_file("#{Rails.root}/media/portfolio/individual_area/#{name_attachment}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
    else
      redirect = {:controller => :home}
      flash[:alert] = t(:no_permission)
      redirect_to redirect
    end
  end

  ##
  # Método que verifica se o usuário tem algum acesso ao arquivo que ele está tentando visualizar (na área pública)
  ##
  def portfolio_public_area
    name_attachment = params[:file] 
    id_file = name_attachment.slice(0..name_attachment.index("_")-1)
    file = PublicFile.find(id_file)

    same_class = Allocation.find_all_by_user_id(current_user.id).map(&:allocation_tag_id).include?(file.allocation_tag_id)
    responsible_class = Profile.user_responsible_of_class(file.allocation_tag_id, current_user.id)

    if same_class or responsible_class
      # path do arquivo anexo a postagem
      type = return_type(params[:extension])
      send_file("#{Rails.root}/media/portfolio/public_area/#{name_attachment}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
    else
      redirect = {:controller => :home}
      flash[:alert] = t(:no_permission)
      redirect_to redirect
    end
  end

  def lesson
    type = return_type(params[:extension])

    # path do arquivo da aula
    send_file("#{Rails.root}/media/lessons/#{params[:id]}/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
    
=begin
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
    #     migrations.pdf
    #     http://www.virtual.ufc.br

    # retorna aulas
    permited_lessons = return_lessons_to_open(offers, groups, params[:id])

    # se tem aula passada em disciplina aberta, pode acessar
    if (permited_lessons.length>0)
      type = return_type(params[:extension])

      # path do arquivo da aula
      send_file("#{Rails.root}/media/lessons/#{params[:id]}/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
    end
=end
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
          begin
            # path do arquivo do anexo da mensagem
            send_file("#{Rails.root}/media/messages/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
          rescue
          end
        end
      end
    end
  end

  # acesso ao material de apoio do curso
#  def support_material_file
#    send_file("#{Rails.root}/media/support_material_file/allocation_tags/#{params[:file_allocation_tag_id]}")
#  end

  
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
