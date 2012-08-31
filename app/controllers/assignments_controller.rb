class AssignmentsController < ApplicationController

  include PortfolioHelper

#filtros
#resources
	before_filter :prepare_for_group_selection, :only => [:list, :list_to_student]

	##
	# Lista as atividades - visão geral
	##	
	def list
		allocation_tag_id      = active_tab[:url]['allocation_tag_id']
    @individual_activities = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Individual_Activity)
    @group_activities      = Assignment.find_all_by_allocation_tag_id_and_type_assignment(allocation_tag_id, Group_Activity)
	end

	##
	# Lista as atividades - visão aluno
	##
	def list_to_student
    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    @student_id = current_user.id
    @individual_activities = Portfolio.student_activities(group_id, @student_id, Individual_Activity) #atividades individuais pelo grupo_id em que o usuario esta inserido
    @group_activities = Portfolio.student_activities(group_id, @student_id, Group_Activity) #atividades em grupo pelo grupo_id em que o usuario esta inserido
    @public_area = Portfolio.public_area(group_id, @student_id) #area publica
	end

	##
  # Informações da atividade individual escolhida na listagem com a lista de alunos daquela turma
  # Informações da atividade em grupo escolhida na listagem com a lista dos grupos daquela turma, permitindo seu gerenciamento
  ##
  def information
		@assignment                    = Assignment.find(params[:id])
    @assignment_enounciation_files = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)  #arquivos que fazem parte da descrição da atividade
    if @assignment.type_assignment == Group_Activity 
      @groups                 = GroupAssignment.find_all_by_assignment_id(@assignment.id)
      @students_without_group = GroupAssignment.students_without_groups(@assignment.id) #alunos da turma sem grupo  
    else
      allocation_tags = AllocationTag.find_related_ids(@assignment.allocation_tag_id).join(',')
      @students       = PortfolioTeacher.list_students_by_allocations(allocation_tags) #alunos participantes da atividade
    end
  end

  ##
  # Avalia trabalho do aluno / grupo
  ##
  def evaluate
    @assignment = Assignment.find(params[:id])
    student_id  = (params[:student_id].nil? or params[:student_id].blank?) ? nil : params[:student_id]
    group_id    = (params[:group_id].nil? or params[:group_id].blank?) ? nil : params[:group_id]
    grade       = params['grade'].blank? ? params['grade'] : params['grade'].tr(',', '.').to_f 
    comment     = params['comment']

    begin
      @send_assignment = SendAssignment.find_or_create_by_assignment_id_and_group_assignment_id_and_user_id(@assignment.id, group_id, student_id)
      @send_assignment.update_attributes!(:grade => grade, :comment => comment)
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
    @assignment       = Assignment.find(params[:id])
    comment           = params[:comment_id].nil? ? nil : AssignmentComment.find(params[:comment_id]) #verifica se comentário já existe. se sim, é edição; se não, é criação.
    student_id        = params[:student_id].nil? ? nil : params[:student_id]
    group_id          = params[:group_id].nil? ? nil : params[:group_id]
    comment_text      = params['comment']
    comment_files     = params['comment_files'].nil? ? [] : params['comment_files']
    deleted_files_ids = params['deleted_files'].nil? ? [] : params['deleted_files'][0].split(",") #["id_arquivo_del1,id_arquivo_del2"] => ["id_arquivo_del1", "id_arquivo_del2"]

    if (comment.nil? or comment.user_id == current_user.id) #se for criar comentário ou se estiver editando o próprio comentário
      send_assignment = SendAssignment.find_or_create_by_group_assignment_id_and_assignment_id_and_user_id(group_id, @assignment.id, student_id)

      begin
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

      rescue Exception => error
        flash[:alert] = error.message
      end
    else
      flash[:alert] = t(:no_permission)
    end
    # flash[:notice] = t(:comment_updated_successfully)
    redirect_to request.referer
  end

  ##
  # Informações do andamento da atividade para um aluno/grupo escolhido
  # Nesta página, há as opções de comentários para o trabalho do aluno/grupo, avaliação e afins
  # => responsáveis: podem comentar/avaliar
  # => alunos: podem enviar/excluir arquivos
  ##
  def show

    #colocar arquivos da atividade
    #aluno também terá acesso a essa página, podendo enviar/excluir arquivos 
    @assignment      = Assignment.find(params[:id]) 
    @student_id      = params[:student_id].nil? ? nil : params[:student_id] 
    @group_id        = params[:group_id].nil? ? nil : params[:group_id] 
    @group           = GroupAssignment.find(params[:group_id]) unless @group_id.nil? #grupo
    @user            = current_user
    @comments_files  = []
    @users_profiles  = []
    @send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(@assignment.id, @student_id, @group_id)
    @assignment_enounciation_files = AssignmentEnunciationFile.find_all_by_assignment_id(@assignment.id)  #arquivos que fazem parte da descrição da atividade
   
    unless @send_assignment.nil? #informações do andamento da atividade do aluno
      @files_sent_assignment = @send_assignment.assignment_files
      @comments              = @send_assignment.assignment_comments.order("updated_at DESC")

      #fazer helper \/

      @comments.each_with_index do |comment, idx|
        profile_id           = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, comment.user_id).profile_id
        @users_profiles[idx] = Profile.find(profile_id)
        @comments_files[idx] = comment.comment_files
      end
    end

    # perfil do usuário para exibir em possíveis novos comentários
    profile_id    = Allocation.find_by_allocation_tag_id_and_user_id(@assignment.allocation_tag_id, current_user.id).profile_id
    @user_profile = Profile.find(profile_id)


#####
    # verifica se os arquivos podem ser deletados
    @delete_files = verify_date_range(@assignment.schedule.start_date.to_time, @assignment.schedule.end_date.to_time, Time.now)
    @situation = Assignment.status_of_actitivy_by_assignment_id_and_student_id(@assignment.id, @student_id)
  end



end
