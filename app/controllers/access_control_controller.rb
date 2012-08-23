include LessonsHelper
include MessagesHelper
include DiscussionPostsHelper
include AccessControlHelper

class AccessControlController < ApplicationController

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

  # http://localhost:3000/media/portfolio/comments/113_ForumDesabilitado.png
  # http://localhost:3000/media/portfolio/individual_area/42_TelaProfessor.png
  ##
  # 
  ##
  def portfolio_files
    attachment_name = params[:file]
    file_id         = attachment_name.slice(0..attachment_name.index("_")-1)
    current_path_split = request.env['PATH_INFO'].split("/")

    case current_path_split[current_path_split.size-2]
      when 'comments'
        file = CommentFile.find(file_id)
        file_send_assignment = file.assignment_comment.send_assignment
        can_access_file = file_send_assignment.assignment.type_assignment != Group_Activity ? file_send_assignment.user_id == current_user.id : !GroupParticipant.find_by_user_id_and_group_assignment_id(current_user.id, file_send_assignment.group_assignment_id).empty? unless file_send_assignment.nil?
      when 'individual_area'
        file = AssignmentFile.find(file_id)
        file_send_assignment = file.send_assignment
        can_access_file = true
      when 'enunciation'
        file = AssignmentEnounciationFile.find(file_id)
        file_send_assignment = file.send_assignment
        can_access_file = true
    end

    related_allocation_tags     = AllocationTag.find_related_ids(file_send_assignment.assignment.allocation_tag_id)
    related_allocations_to_user = Allocation.where(:allocation_tag_id => related_allocation_tags, :user_id => current_user.id) unless related_allocation_tags.empty?
    user_related = true unless related_allocation_tags.empty? or related_allocations_to_user.empty?

    if (file_send_assignment.assignment.allocation_tag.is_user_class_responsible?(current_user.id) or can_access_file) and user_related
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

end
