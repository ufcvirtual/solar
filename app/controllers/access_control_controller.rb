include LessonsHelper
include MessagesHelper
include DiscussionPostsHelper

class AccessControlController < ApplicationController

  def portfolio_individual_area
    attachment_name = params[:file]
    file_id = attachment_name.slice(0..attachment_name.index("_")-1)
    assignment_file = AssignmentFile.find(file_id)
    assignment = assignment_file.assignment
    
    student_individual_activity_or_part_of_the_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment.id, current_user.id, file_id)

    if student_individual_activity_or_part_of_the_group
      type = return_type(params[:extension])
      send_file(assignment_file.attachment.path, { :disposition => 'inline', :type => type} )
    else
      no_permission_redirect
    end
  end

  def portfolio_public_area
    attachment_name = params[:file]
    file_id = attachment_name.slice(0..attachment_name.index("_")-1)
    file = PublicFile.select("allocation_tag_id, id, attachment_file_name").includes(:allocation_tag).find(file_id)

    same_class = Allocation.find_all_by_user_id(current_user.id).map(&:allocation_tag_id).include?(file.allocation_tag_id)
    class_responsible = file.allocation_tag.is_user_class_responsible?(current_user.id)

    if same_class or class_responsible
      type = return_type(params[:extension])
      send_file(file.attachment.path, { :disposition => 'inline', :type => type} )
    else
      no_permission_redirect
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
  
  def no_permission_redirect
    redirect = {:controller => :home}
    flash[:alert] = t(:no_permission)
    redirect_to redirect
  end

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
