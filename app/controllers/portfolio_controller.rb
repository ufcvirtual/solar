class PortfolioController < ApplicationController
  include FilesHelper

#  before_filter :require_user
  before_filter :prepare_for_group_selection, :only => [:list]

  ##
  # Lista as atividades
  ##
  def list
    authorize! :list, Portfolio

    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id

    # listando atividades individuais pelo grupo_id em que o usuario esta inserido
    @individual_activities = Portfolio.student_activities(group_id, current_user.id, Individual_Activity)
    # Listando atividades em grupo pelo grupo_id em que o usuario esta inserido
    @group_activities = Portfolio.student_activities(group_id, current_user.id, Group_Activity)

    # Receberá os participantes do grupo de determinada atividade
    @groups_participants = []
    # Receberá o nome do grupo de determinada atividade
    @groups_names = []

    for activity in @group_activities
      @groups_participants[activity["id"].to_i] = Portfolio.find_group_participants(activity["id"].to_i, current_user.id)
      @groups_names[activity["id"].to_i] = @groups_participants[activity["id"].to_i].first.group_assignment.group_name unless @groups_participants[activity["id"].to_i].nil?
    end
    
    # area publica
    @public_area = Portfolio.public_area(group_id, current_user.id)
  end

  ##
  # Detalhes de uma atividade e arquivos da area publica
  ##
  def activity_details
    authorize! :activity_details, Portfolio

    assignment_id = params[:id]

    # recupera a atividade selecionada
    @activity = Portfolio.find(assignment_id, :joins => :schedule)

    # verifica se os arquivos podem ser deletados
    @delete_files = verify_date_range(@activity.schedule.start_date.to_time, @activity.schedule.end_date.to_time, Time.now)

    # recuperar o send_assignment
    student_id = current_user.id

   if @activity.type_assignment == Individual_Activity
    # recupera os arquivos enviados pelo aluno
    send_assignment1 = Portfolio.assignments_student(student_id, assignment_id)
   elsif @activity.type_assignment == Group_Activity
    # recupera os arquivos enviados pelo grupo
    groups_participants = Portfolio.find_group_participants(@activity.id, current_user.id)
    group_assignment_id = groups_participants.first.group_assignment_id unless groups_participants.nil?
    send_assignments = SendAssignment.find_all_by_assignment_id_and_group_assignment_id(assignment_id, group_assignment_id)
   end

    @grade = nil # nota dada pelo professor a atividade enviada
    @comments = [] # comentario do professor
    @files_sent = [] # arquivos enviados pelo aluno ou grupo
    @files_comments = [] # arquivos dos comentarios enviados pelo professor

    # verifica se o aluno ou o grupo respondeu a atividade
    unless send_assignments.nil?
      # nota
      @grade = send_assignments.first.grade

      # listagem de arquivos enviados pelo aluno ou grupo para a atividade
      for send_assignment2 in send_assignments
        for file in AssignmentFile.find_all_by_send_assignment_id(send_assignment2.id)
          @files_sent << file
        end
        comment_assignment = AssignmentComment.find_by_send_assignment_id(send_assignment2.id)
        @comments << comment_assignment.comment unless comment_assignment.nil?
        unless comment_assignment.nil?
          for comment_file in CommentFile.all(:conditions => ["assignment_comment_id = ?", AssignmentComment.find_by_comment(comment_assignment.comment).id]) 
            @files_comments << comment_file
          end
        end
      end 
    end

    unless send_assignment1.nil?
      for file in AssignmentFile.find_all_by_send_assignment_id(send_assignment1.id)
          @files_sent << file
      end
      comment_assignment = AssignmentComment.find_by_send_assignment_id(send_assignment1.id)
      @comment << comment_assignment.comment unless comment_assignment.nil?
      unless comment_assignment.nil?
          for comment_file in CommentFile.all(:conditions => ["assignment_comment_id = ?", AssignmentComment.find_by_comment(comment_assignment.comment).id]) 
            @files_comments << comment_file
          end
      end
    end

    @situation = Assignment.status_of_actitivy_by_assignment_id_and_student_id(assignment_id, student_id)


    # Nome do grupo da atividade e uma lista com o "group_participants" desse grupo.
    # Caso o aluno não esteja em nenhum grupo ou seja trabalho individual, serão nulos.
    @group_participants = Portfolio.find_group_participants(@activity.id, current_user.id)
    @group_name = @group_participants.first.group_assignment.group_name unless @group_participants.nil?

  end

  ##
  # Delecao de arquivos da area individual
  ##
  def delete_file_individual_area
    authorize! :delete_file_individual_area, Portfolio

    assignment_id = params[:assignment_id]
    file_id = params[:id]
    redirect = {:controller => :portfolio, :action => :activity_details, :id => assignment_id}

    # verificação se usuário está relacionado com a atividade em questão
    user_is_related = Portfolio.user_related_with_activity(assignment_id, current_user.id)
    # verificação se o arquivo individual é dele ou se faz parte do grupo
    individual_activity_or_part_of_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment_id, current_user.id, file_id)
    
    if user_is_related && individual_activity_or_part_of_group
      respond_to do |format|
        begin
          # verifica periodo para delecao das atividades
          assignment = Portfolio.find(assignment_id)
          start_date = assignment.schedule.start_date
          end_date = assignment.schedule.end_date

          # verifica permissao de intervalo de datas para deletar arquivos
          raise t(:delete_file_interval_error) unless verify_date_range(start_date.to_time, end_date.to_time, Time.now)

          # recupera o nome do arquivo a ser feito o download
          filename = AssignmentFile.find(file_id).attachment_file_name

          # arquivo a ser deletado
          file_del = "#{::Rails.root.to_s}/media/portfolio/individual_area/#{file_id}_#{filename}"
          error = false

          # deletar o arquivo da base de dados
          error = true unless AssignmentFile.find(file_id).delete

          # deletar o arquivo do servidor
          unless error
            File.delete(file_del) if File.exist?(file_del)

            flash[:notice] = t(:file_deleted)
            format.html { redirect_to(redirect) }

          else
            raise t(:error_delete_file)
          end

        rescue Exception
          flash[:alert] = t(:error_delete_file)
          format.html {redirect_to(redirect)}
        end
      end
    else
      controller_curriculum_unit = {:controller => :curriculum_units, :action => :show, :id => active_tab[:url]['id']}
      redirect = ((active_tab[:url]['context'] == Context_Curriculum_Unit) ? controller_curriculum_unit : {:controller => :home})
      flash[:alert] = t(:no_permission)
      redirect_to redirect
    end
  end

  ##
  # Download dos arquivos do comentario do professor
  ##
  def download_file_comment
    authorize! :download_file_comment, Portfolio

    curriculum_unit_id = active_tab[:url]["id"]
    download_file({:action => :list, :id => curriculum_unit_id}, CommentFile.find(params[:id]).attachment.path)
  end

  ##################
  #  AREA PUBLICA
  ##################

  ##
  # Envio de arquivos para a area publica
  ##
  def upload_files_public_area

    authorize! :upload_files_public_area, Portfolio

    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => :list, :id => params[:curriculum_unit_id]}

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:portfolio)

        # allocation_tag do grupo selecionada
        allocation_tag_id = active_tab[:url]['allocation_tag_id']

        @public_file = PublicFile.new params[:portfolio]
        @public_file.user_id = current_user.id
        @public_file.allocation_tag_id = allocation_tag_id
        @public_file.save!

        # arquivo salvo com sucesso
        flash[:notice] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error

        flash[:alert] = error.message # @public_file.errors.full_messages
        format.html { redirect_to(redirect) }

      end
    end
  end

  # Delecao de arquivos da area publica
  def delete_file_public_area

    authorize! :delete_file_public_area, Portfolio

    curriculum_unit_id = active_tab[:url]['id']
    redirect = {:action => :list, :id => curriculum_unit_id}

    respond_to do |format|
      begin
        # arquivo a ser deletado
        file_name = PublicFile.find(params[:id]).attachment_file_name
        file_del = "#{::Rails.root.to_s}/media/portfolio/public_area/#{params[:id]}_#{file_name}"

        error = false

        # deletar arquivo da base de dados
        error = true unless PublicFile.find(params[:id]).delete

        # deletar arquivo do servidor
        unless error
          File.delete(file_del) if File.exist?(file_del)

          flash[:notice] = t(:file_deleted)
          format.html { redirect_to(redirect) }

        else
          raise t(:error_delete_file) unless error == 0
        end

      rescue Exception
        flash[:alert] = t(:error_delete_file)
        format.html { redirect_to(redirect) }
      end
    end
  end

  # Download dos arquivos da area publica
  def download_file_public_area
    authorize! :download_file_public_area, Portfolio

    curriculum_unit_id = active_tab[:url]["id"]
    download_file({:action => 'list', :id => curriculum_unit_id}, PublicFile.find(params[:id]).attachment.path)
  end

  ####################
  #  AREA INDIVIDUAL
  ####################

  ##
  # Envio de arquivos como resposta para a atividade
  ##
  def upload_files_individual_area

    authorize! :upload_files_individual_area, Portfolio

    assignment_id = params[:assignment_id]

    # redireciona para os detalhes da atividade individual
    redirect = {:action => :activity_details, :id => assignment_id}

    respond_to do |format|
      begin

        # verificar intervalo de envio de arquivos
        activity = Portfolio.find(assignment_id)
        # verifica se os arquivos podem ser deletados
        raise t(:send_file_interval_error) unless verify_date_range(activity.schedule.start_date.to_time, activity.schedule.end_date.to_time, Time.now)

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:assignment_file)

        # verifica se a atividade ja foi respondida para aquele usuario
        send_assignment = SendAssignment.where(["assignment_id = ? AND user_id = ?", params[:assignment_id], current_user.id]).first
        send_assignment_id = send_assignment.nil? ? nil : send_assignment[:id] # verificando se ja existe um id para setar na tabela de arquivos

        # se nao existir id criado no send_assignment, devera ser criado
        if send_assignment_id.nil?
          send_assignment = SendAssignment.new do |sa|
            sa.assignment_id = params[:assignment_id]
            sa.user_id = current_user.id
            sa.group_assignment_id = params[:group_assignment_id]
          end

          send_assignment.save!
        end

        # salvando arquivos na base de dados
        assignment_file = AssignmentFile.new params[:assignment_file]
        assignment_file.send_assignment_id = send_assignment.id
        assignment_file.save!

        flash[:notice] = t(:file_uploaded)
        format.html { redirect_to(redirect) }
      rescue Exception => error
        flash[:alert] = error.message
        format.html { redirect_to(redirect) }
      end
    end
  end

  ##
  # Download dos arquivos da area individual
  ##
  def download_file_individual_area
    authorize! :download_file_individual_area, Portfolio

    file_id = params[:id]

    # id da atividade
    assignment_id = SendAssignment.find(AssignmentFile.find(params[:id]).send_assignment_id).assignment_id

    # verificação se usuário está relacionado com a atividade em questão
    user_is_related = Portfolio.user_related_with_activity(assignment_id, current_user.id)
    # verificação se o arquivo individual é dele ou se faz parte do grupo
    individual_activity_or_part_of_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment_id, current_user.id, file_id)
    
    if user_is_related && individual_activity_or_part_of_group
      download_file({:action => 'activity_details', :id => assignment_id}, AssignmentFile.find(file_id).attachment.path)
    else
      controller_curriculum_unit = {:controller => :curriculum_units, :action => :show, :id => active_tab[:url]['id']}
      redirect = ((active_tab[:url]['context'] == Context_Curriculum_Unit) ? controller_curriculum_unit : {:controller => :home})
      flash[:alert] = t(:no_permission)
      redirect_to redirect
    end
  end

  #Formulário de upload exibido numa lightbox
  def public_files_send
    render :layout => false
  end

  ###################
  # Funcoes privadas
  ###################

  private

  # Verifica se uma data esta em um intervalo de outras
  def verify_date_range(start_date, end_date, date)
    return date > start_date && date < end_date
  end

end



