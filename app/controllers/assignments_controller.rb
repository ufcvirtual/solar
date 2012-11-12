class AssignmentsController < ApplicationController

  include AssignmentsHelper
  include FilesHelper
  include EditionHelper

  before_filter :prepare_for_group_selection, :only => [:list, :list_to_student]
  load_and_authorize_resource :only => [:information, :show, :import_groups_page, :import_groups, :manage_groups, :evaluate, :send_comment, :remove_comment]
  authorize_resource :only => [:list, :list_to_student, :download_files, :upload_file, :send_public_files_page, :delete_file]

  ##
  # Lista as atividades - visão geral
  ##  
  def list
    allocation_tags_ids    = params[:allocation_tags_ids] || [active_tab[:url]['allocation_tag_id']]
    @individual_activities = allocation_tags_ids.collect{|at| Assignment.find_all_by_allocation_tag_id_and_type_assignment(at, Individual_Activity)}.flatten.uniq
    @group_activities      = allocation_tags_ids.collect{|at| Assignment.find_all_by_allocation_tag_id_and_type_assignment(at, Group_Activity)}.flatten.uniq
    # @group_and_offer_info  = group_and_offer_info(params[:group_id], params[:offer_id]) # complementará o texto do título da página quando for acessada pela página de edição

    render :layout => false if params[:allocation_tags_ids]
  end

  ##
  # Lista as atividades - visão aluno
  ##
  def list_to_student
    group_id                     = params['selected_group']
    @student_id                  = current_user.id
    @individual_assignments_info = Assignment.student_assignments_info(group_id, @student_id, Individual_Activity) # atividades individuais pelo grupo_id em que o usuario esta inserido
    @group_assignments_info      = Assignment.student_assignments_info(group_id, @student_id, Group_Activity) # atividades em grupo pelo grupo_id em que o usuario esta inserido
    @public_area                 = PublicFile.all_by_class_id_and_user_id(group_id, @student_id)
  end

  ##
  # Informações da atividade individual escolhida na listagem com a lista de alunos daquela turma
  # Informações da atividade em grupo escolhida na listagem com a lista dos grupos daquela turma, permitindo seu gerenciamento
  ##
  def information
    @assignment_enunciation_files = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)  #arquivos que fazem parte da descrição da atividade
    if @assignment.type_assignment == Group_Activity 
      @groups                 = GroupAssignment.find_all_by_assignment_id(@assignment.id)
      @students_without_group = @assignment.students_without_groups
    else
      allocation_tags = AllocationTag.find_related_ids(@assignment.allocation_tag_id).join(',')
      @students       = Assignment.list_students_by_allocations(allocation_tags) #alunos participantes da atividade
    end
  end

  ##
  # Gerenciamento de grupos da atividade
  ##
  def manage_groups
    deleted_groups_ids      = params['deleted_groups_divs_ids'].blank? ? [] : params['deleted_groups_divs_ids'].collect{ |group| group.tr('_', ' ').split[1] } #"group_2" => 2
   
    unless params['btn_cancel'] # clicou em "salvar"
      begin
        # verifica se ainda está no prazo
        raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment_in_time?(@assignment)

        GroupAssignment.transaction do
          deleted_groups_ids.each do |deleted_group_id| # deleção de grupos
            GroupAssignment.find(deleted_group_id).destroy unless (not GroupAssignment.can_remove_group?(deleted_group_id))
          end

          # params['groups'] = {"0"=>{"group_id"=>"1", "group_name"=>"grupo1", "student_ids"=>"1 2"}, "1"=>{"group_id"=>"2", "group_name"=>"grupo2", "student_ids"=>"3"}}
          params['groups'].each do |group| # criação/edição de grupos
            group_id = group[1]['group_id'] #["0", {"group_id"=>"1", "group_name"=>"grupo1", "student_ids"=>"1 2"}] => 1
            group_participants_ids = (group[1]['student_ids'].split).collect{|participant| participant.to_i} unless group[1]['student_ids'].nil? #or group[1]['student_ids'] == 0 # => "1 2" => ["1","2"] => [1,2]
            unless group_id.nil? # se não forem alunos sem grupo
              group_name = group[1]['group_name']
              if group_id == '0' # novo grupo
                group_assignment = GroupAssignment.create!(:assignment_id => @assignment.id, :group_name => group_name)
              else # grupo já existente
                group_assignment = GroupAssignment.find(group_id)
                group_assignment.update_attributes!(:group_name => group_name)
              end
            end

            # altera os alunos de grupo a não ser que o grupo não possa ser alterado/excluido e que este esteja na lista de grupos que foram excluídos
            change_students_group(group_assignment, group_participants_ids, @assignment.id) unless ((not GroupAssignment.can_remove_group?(group_id)) and deleted_groups_ids.include?("#{group_id}"))
          end

          @students_without_group = @assignment.students_without_groups

          respond_to do |format|
            format.html { render 'group_assignment_content_div', :layout => false }
          end

        end
      rescue Exception => error
        render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
      end
    else # clicou em "cancelar"
      @students_without_group = @assignment.students_without_groups
      respond_to do |format|
        format.html { render 'group_assignment_content_div', :layout => false }
      end
    end
  end

  ##
  # Informações do andamento da atividade para um aluno/grupo escolhido
  # Nesta página, há as opções de comentários para o trabalho do aluno/grupo, avaliação e afins
  # => responsáveis: podem comentar/avaliar
  # => alunos: podem enviar/excluir arquivos
  ##
  def show
    @user            = current_user
    @student_id      = params[:group_id].nil? ? params[:student_id] : nil
    @group_id        = params[:group_id].nil? ? nil : params[:group_id] 
    @group           = GroupAssignment.find(params[:group_id]) unless @group_id.nil? # grupo
    @send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(@assignment.id, @student_id, @group_id)
    @situation       = Assignment.assignment_situation_of_student(@assignment.id, @student_id, @group_id)
    @assignment_enunciation_files = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)  # arquivos que fazem parte da descrição da atividade

    raise CanCan::AccessDenied unless @assignment.user_can_access_assignment(current_user.id, @student_id, @group_id)
   
    unless @send_assignment.nil?
      @send_assignment_files = @send_assignment.assignment_files
      @comments              = @send_assignment.assignment_comments
    end
  end

  ##
  # Avalia trabalho do aluno / grupo
  ##
  def evaluate
    @student_id = (params[:student_id].nil? or params[:student_id].blank?) ? nil : params[:student_id]
    @group_id   = (params[:group_id].nil? or params[:group_id].blank?) ? nil : params[:group_id]
    grade       = params['grade'].blank? ? params['grade'] : params['grade'].tr(',', '.') 
    begin
      raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment_in_time?(@assignment) # verifica se está no prazo
      @send_assignment = SendAssignment.find_or_create_by_assignment_id_and_group_assignment_id_and_user_id(@assignment.id, @group_id, @student_id)
      @send_assignment.update_attributes!(:grade => grade)
      @situation       = Assignment.assignment_situation_of_student(@assignment.id, @student_id, @group_id)
      respond_to do |format|
        format.html { render 'evaluate_assignment_div', :layout => false }
      end
    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message.split(',')[0], :flash_class => 'alert' }
    end
  end

  ##
  # Envia comentarios do professor (cria e edita)
  ##
  def send_comment
    comment           = params[:comment_id].nil? ? nil : AssignmentComment.find(params[:comment_id]) # verifica se comentário já existe. se sim, é edição; se não, é criação.
    authorize! :send_comment, comment unless comment.nil?
    student_id        = params[:student_id].nil? ? nil : params[:student_id]
    group_id          = params[:group_id].nil? ? nil : params[:group_id]
    comment_text      = params['comment']
    comment_files     = params['comment_files'].nil? ? [] : params['comment_files']
    deleted_files_ids = params['deleted_files'].nil? ? [] : params['deleted_files'][0].split(",") # ["id_arquivo_del1,id_arquivo_del2"] => ["id_arquivo_del1", "id_arquivo_del2"]
    send_assignment   = SendAssignment.find_or_create_by_group_assignment_id_and_assignment_id_and_user_id(group_id, @assignment.id, student_id) # busca ou cria send_assignment ao aluno/grupo

    begin
      raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment_in_time?(@assignment) # verifica se está no prazo
      ActiveRecord::Base.transaction do

        if comment.nil?
          comment = AssignmentComment.create!(:user_id => current_user.id, :comment => comment_text, :send_assignment_id => send_assignment.id, :updated_at => Time.now)
        else
          comment.update_attributes!(:comment => comment_text, :updated_at => Time.now)
        end
        
        comment_files.each do |file|
          CommentFile.create!({ :attachment => file, :assignment_comment_id => comment.id })
        end

        deleted_files_ids.each do |deleted_file_id|
          CommentFile.find(deleted_file_id).delete_comment_file unless deleted_file_id.blank?
        end
      end

      flash[:notice] = t(:comment_sent_success, :scope => [:assignment, :comments])
    rescue Exception => error
      flash[:alert] = error.message
    end

    redirect_to request.referer.nil? ? root_url(:only_path => false) : request.referer
  end

  ##
  # Remover comentário
  ##
  def remove_comment
    comment = AssignmentComment.find(params[:comment_id])
    authorize! :remove_comment, comment
    begin
      ActiveRecord::Base.transaction do
        comment.comment_files.each do |file|
          file.delete_comment_file
        end
        comment.delete
      end
      render :json => { :success => true, :flash_msg => t(:removed_comment, :scope => [:assignment, :comments]), :flash_class => 'notice' }
    rescue Exception => error
      render :json => { :success => false, :flash_msg => error.message, :flash_class => 'alert' }
    end
  end

  ##
  # Download dos arquivos do portfolio (seja enviado pelo aluno/grupo, enviado no comentário do professor, que faça parte da descrição da atividade ou arquivo público)
  ##
  def download_files
    assignment = Assignment.find(params[:assignment_id]) unless params[:assignment_id].nil?
    authorize! :download_files, assignment unless assignment.nil?

    if params.include?('zip') # se for baixar todos como zip
      folder_name = ''
      case params[:type]
        when 'assignment' # arquivos enviados pelo aluno/grupo
          send_assignment = assignment.send_assignments.where(:user_id => params[:student_id], :group_assignment_id => params[:group_id]).first
          folder_name     = [assignment.name, (params[:group_id].nil? ? send_assignment.user.nick : send_assignment.group_assignment.group_name)].join(' - ')# pasta: "atv1 - aluno1"
          all_files       = send_assignment.assignment_files
          raise CanCan::AccessDenied unless assignment.user_can_access_assignment(current_user.id, params[:student_id], params[:group_id])
        when 'enunciation' # arquivos que fazem parte da descrição da atividade
          folder_name = assignment.name # pasta: "atv1"
          all_files = assignment.assignment_enunciation_files
      end
      file_path = make_zip_files(all_files, 'attachment_file_name', folder_name) # caminho do zip criado
    else
      case params[:type]
        when 'comment' # arquivo de um comentário
          file = CommentFile.find(params[:file_id])
          send_assignment = file.assignment_comment.send_assignment
        when 'assignment' # arquivo enviado pelo aluno/grupo
          file = AssignmentFile.find(params[:file_id])
          send_assignment = file.send_assignment
        when 'enunciation' # arquivo que faz parte da descrição da atividade
          file = AssignmentEnunciationFile.find(params[:file_id])
        when 'public'
          file = PublicFile.find(params[:file_id]) # área pública do aluno
          group = file.allocation_tag.groups.first
          raise CanCan::AccessDenied if group.nil? # turma não existe
          # authorize! :related_with_allocation_tag,  AllocationTag.user_allocation_tag_related_with_class(group.id, current_user.id) # verifica se pode acessar turma
      end
      file_path = file.attachment.path
      file_name = file.attachment_file_name unless file.nil?
    end

    # verifica, se é responsável da classe ou aluno que esteja acessando informações dele mesmo
    raise CanCan::AccessDenied unless (assignment.nil? or send_assignment.nil? or assignment.user_can_access_assignment(current_user.id, send_assignment.user_id, send_assignment.group_assignment_id))
    redirect = request.referer.nil? ? root_url(:only_path => false) : request.referer
    download_file(redirect, file_path, file_name)
  end

  ##
  # Página de envio dos arquivos públicos
  ##
  def send_public_files_page
    render :layout => false
  end

  ##
  # Upload de arquivos públicos ou de uma atividade
  ##
  def upload_file
    begin 
      file = case params[:type]
        when "public"
          allocation_tag_id = active_tab[:url]['allocation_tag_id']
          raise CanCan::AccessDenied unless Profile.student_from_class?(current_user.id, allocation_tag_id)
          PublicFile.create!({ :attachment => params[:file], :user_id => current_user.id, :allocation_tag_id => allocation_tag_id })
        when "assignment"
          assignment = Assignment.find(params[:assignment_id])
          authorize! :upload_file, assignment

          group = GroupAssignment.first(:include => [:group_participants], :conditions => ["assignment_id = #{assignment.id} AND group_participants.user_id = #{current_user.id}"])
          group_id = group.nil? ? nil : group.id
          user_id  = group.nil? ? current_user.id : nil

          # verifica, se é responsável da classe ou aluno que esteja acessando informações dele mesmo
          raise CanCan::AccessDenied unless assignment.user_can_access_assignment(current_user.id, current_user.id, group_id)
          raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment_in_time?(assignment) # verifica período para envio do arquivo

          send_assignment = SendAssignment.find_or_create_by_assignment_id_and_user_id_and_group_assignment_id!(assignment.id, user_id, group_id)
          AssignmentFile.create!({ :attachment => params[:file], :send_assignment_id => send_assignment.id, :user_id => current_user.id })
      end

      flash[:notice] = t(:uploaded_success, :scope => [:assignment, :files])
    rescue Exception => error
      flash[:alert] = error.message.split(',')[0]
    end
    redirect_to (request.referer.nil? ? root_url(:only_path => false) : request.referer)
  end

  def delete_file
    begin
      case params[:type]
        when 'public'
          file = PublicFile.find(params[:file_id])
          raise CanCan::AccessDenied unless file.user_id == current_user.id

          if file.delete
            File.delete(file.attachment.path) if File.exist?(file.attachment.path)
          else
            raise t(:error_delete, :scope => [:assignment, :files])
          end

        when 'assignment'
          assignment = Assignment.find(params[:assignment_id])
          authorize! :delete_file, assignment

          raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment_in_time?(assignment) # verifica prazo
          # verifica, se é responsável da classe ou aluno que esteja acessando informações dele mesmo
          raise CanCan::AccessDenied unless assignment.user_can_access_assignment(current_user.id, AssignmentFile.find(params[:file_id]).user_id)

          AssignmentFile.find(params[:file_id]).delete_assignment_file
      end
      flash[:notice] = t(:deleted_success, :scope => [:assignment, :files])
    rescue Exception => error
      flash[:alert] = error.message
    end
    redirect_to (request.referer.nil? ? root_url(:only_path => false) : request.referer)
  end

  ##
  # Página de importação de grupos (lightbox)
  # => @assignments: todas as atividades da turma acessada pelo usuário no momento
  # => @assignment_id: a atividade que irá importar os grupos
  ##
  def import_groups_page
    group_id       = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    @assignments   = GroupAssignment.all_by_group_id(group_id)
    @assignments.delete(@assignment)
    render :layout => false
  end

  ##
  # Importação de grupos
  ##
  def import_groups
    import_to_assignment_id   = params[:id] # para qual atividade os grupos serão importados
    import_from_assignment_id = params[:assignment_id_import_from] # de qual atividade os grupos serão importados
    groups_to_import          = GroupAssignment.find_all_by_assignment_id(import_from_assignment_id) # grupos a serem importados

    begin 
      # verifica período para envio do arquivo
      raise t(:date_range_expired, :scope => [:assignment, :notifications]) unless assignment_in_time?(@assignment)

      unless groups_to_import.empty?
        groups_to_import.each do |group_to_import|
          group_imported = GroupAssignment.create(:group_name => group_to_import.group_name, :assignment_id => import_to_assignment_id) # grupo importado
          group_to_import.group_participants.each do |participant_to_import|
            GroupParticipant.create(:group_assignment_id => group_imported.id, :user_id => participant_to_import.user_id)
          end
        end
      end

      flash[:notice] = t(:import_success, :scope => [:assignment, :import_groups])

    rescue Exception => error
      flash[:alert] = error.message
    end
    redirect_to information_assignment_path(@assignment)
  end

  private

    ##
    # Método que realiza as mudanças de um grupo e realiza as trocas de alunos
    ##
    def change_students_group(group_assignment, students_ids, assignment_id)
      unless students_ids.nil?
        students_ids.each do |student_id|
          # groupo atual do aluno nesta atividade
          current_group_participant     = Assignment.find(assignment_id).group_participants.where(user_id: student_id).first # aluno esta em apenas um grupo por atividade

          # send_assignment do grupo atual
          current_group_send_assignment = current_group_participant.group_assignment.send_assignment unless current_group_participant.nil?
          student_files_current_group   = current_group_send_assignment.assignment_files.where(user_id: student_id) unless current_group_send_assignment.nil?

          # send_assignment do grupo ao qual aluno tentará ser movido
          choosen_group_send_assignment = group_assignment.send_assignment unless group_assignment.nil?

          student_can_be_removed_from_current_group = (student_files_current_group.nil? and (current_group_send_assignment.nil? or current_group_send_assignment.grade.nil?))
          student_can_be_moved_to_choosen_group     = (choosen_group_send_assignment.nil? or choosen_group_send_assignment.grade.nil?)
          # se:
            # => aluno não enviou arquivos ao grupo atual E send_assignment do grupo não existe ou não foi avaliado
            # => novo grupo não tenha send_assignment ou não tenha sido avaliado
          if (student_can_be_removed_from_current_group and student_can_be_moved_to_choosen_group)
            unless group_assignment.nil?
              if current_group_participant.nil?
                GroupParticipant.create!(:group_assignment_id => group_assignment["id"], :user_id => student_id)
              elsif current_group_participant.group_assignment_id != group_assignment.id
                current_group_participant.update_attributes!(:group_assignment_id => group_assignment.id)
              end
            else
              current_group_participant.delete unless current_group_participant.nil? 
            end
          end # end if
        end
      end # end unless
    end

end