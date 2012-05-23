include LessonsHelper
include MessagesHelper
include DiscussionPostsHelper

class AccessControlController < ApplicationController

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
    send_file("#{Rails.root}/media/lessons/#{params[:id]}/#{params[:file]}.#{params[:extension]}", { :disposition => 'inline', :type => type} )
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
