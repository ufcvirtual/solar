include LessonsHelper
include MessagesHelper
include DiscussionPostsHelper
include AccessControlHelper

class AccessControlController < ApplicationController

  ## 
  # Verificação de acesso ao realizar download de um arquivo relacionado à atividades ou um arquivo público
  ##
  def assignment
    attachment_name    = params[:file] 
    file_id            = attachment_name.slice(0..attachment_name.index("_")-1) 
    current_path_split = request.env['PATH_INFO'].split("/") #ex: /media/assignment/public_area/20_crimescene.png => ["", "media", "assignment", "public_area", "20_crimescene.png"]

    case current_path_split[current_path_split.size-2] #ex: ["", "media", "assignment", "public_area", "20_crimescene.png"] => public_area
      when 'comments' #arquivo de um comentário
        file = CommentFile.find(file_id)
        send_assignment = file.assignment_comment.send_assignment
        authorize! :download_files, send_assignment.assignment
      when 'sent_assignment_files' #arquivo enviado pelo aluno/grupo
        file = AssignmentFile.find(file_id)
        send_assignment = file.send_assignment
        authorize! :download_files, send_assignment.assignment
      when 'enunciation' #arquivo que faz parte da descrição da atividade
        file = AssignmentEnunciationFile.find(file_id)
        authorize! :download_files, file.assignment
      when 'public_area' #área pública do aluno
        file = PublicFile.find(file_id) 
        authorize! :download_files, Assignment
        same_class = Allocation.find_all_by_user_id(current_user.id).map(&:allocation_tag_id).include?(file.allocation_tag_id)
    end

    #verifica se tem acesso a arquivo ou se é da mesma turma (definido apenas para arquivos públicos)
    if (!send_assignment.nil? and send_assignment.assignment.user_can_access_assignment(current_user.id, send_assignment.user_id, send_assignment.group_assignment_id)) or (same_class)
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
