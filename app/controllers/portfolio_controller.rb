class PortfolioController < ApplicationController
  include FilesHelper
  include PortfolioHelper

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

    # Nome do grupo da atividade e uma lista com o "group_participants" desse grupo.
    # Caso o aluno não esteja em nenhum grupo ou seja trabalho individual, serão nulos.
    @group_participants = Portfolio.find_group_participants(@activity.id, current_user.id)
    @group_name = @group_participants.first.group_assignment.group_name unless @group_participants.nil?

   if @activity.type_assignment == Individual_Activity
    # recupera os arquivos enviados pelo aluno
    send_assignment = SendAssignment.find_by_assignment_id_and_user_id(assignment_id, student_id)
   elsif @activity.type_assignment == Group_Activity
    # recupera os arquivos enviados pelo grupo
    group_assignment_id = @group_participants.first.group_assignment_id unless @group_participants.nil?
    send_assignment = SendAssignment.find_by_assignment_id_and_group_assignment_id(assignment_id, group_assignment_id)
   end

    @grade = nil # nota dada pelo professor a atividade enviada
    @comments = [] # comentario do professor
    @files_sent = [] # arquivos enviados pelo aluno ou grupo
    @files_comments = [] # arquivos dos comentarios enviados pelo professor

    # verifica se o aluno ou o grupo respondeu a atividade
    unless send_assignment.nil?
      @grade = send_assignment.grade
      # listagem de arquivos enviados pelo aluno ou grupo para a atividade
      @files_sent = AssignmentFile.find_all_by_send_assignment_id(send_assignment.id)
      comment_assignment = AssignmentComment.find_by_send_assignment_id(send_assignment.id)
      # listagem de comentários para cada send_assignment existente (no caso de grupo, pois em trabalho individual existirá apenas um)
      @comments = comment_assignment.comment unless comment_assignment.nil?
      # listagem dos arquivos anexados pelo professor
      @files_comments = CommentFile.all(:conditions => ["assignment_comment_id = ?", AssignmentComment.find_by_comment(comment_assignment.comment).id]) unless comment_assignment.nil?
    end

    @situation = Assignment.status_of_actitivy_by_assignment_id_and_student_id(assignment_id, student_id)
  end

  ##
  # Delecao de arquivos da area individual
  ##
  def delete_file_individual_area
    authorize! :delete_file_individual_area, Portfolio

    assignment_id = params[:assignment_id]
    file_id = params[:id]
    redirect = {:controller => :portfolio, :action => :activity_details, :id => assignment_id}

    # verificação se o arquivo individual é dele ou se faz parte do grupo
    individual_activity_or_part_of_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment_id, current_user.id, file_id)

    if individual_activity_or_part_of_group
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
      no_permission_redirect
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

    if PublicFile.find(params[:id]).user_id == current_user.id
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
    else
      no_permission_redirect
    end
  end

  # Download dos arquivos da area publica
  def download_file_public_area
    authorize! :download_file_public_area, Portfolio

    file = PublicFile.find(params[:id])

    same_class = Allocation.find_all_by_user_id(current_user.id).map(&:allocation_tag_id).include?(file.allocation_tag_id)

    if same_class
      curriculum_unit_id = active_tab[:url]["id"]
      download_file({:action => 'list', :id => curriculum_unit_id}, PublicFile.find(file.id).attachment.path)
    else
      no_permission_redirect
    end
  end

  ####################
  #  AREA INDIVIDUAL
  ####################

  ##
  # Envio de arquivos como resposta para a atividade
  ##
  def upload_files_individual_area

    authorize! :upload_files_individual_area, Portfolio

    assignment = Assignment.find(params[:assignment_id])

    # redireciona para os detalhes da atividade individual
    redirect = {:action => :activity_details, :id => assignment.id}

    # verificação se o arquivo individual é dele ou se faz parte do grupo
    individual_activity_or_part_of_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment.id, current_user.id)

    if individual_activity_or_part_of_group
      respond_to do |format|
        begin
          # verificar intervalo de envio de arquivos
          activity = Portfolio.find(assignment.id)
          # verifica se os arquivos podem ser deletados
          raise t(:send_file_interval_error) unless verify_date_range(activity.schedule.start_date.to_time, activity.schedule.end_date.to_time, Time.now)

          # verifica se o arquivo foi adicionado
          raise t(:error_no_file_sent) unless params.include?(:assignment_file)

          # verifica se a atividade ja foi respondida para aquele usuario
          if assignment.type_assignment == Individual_Activity
            send_assignment = SendAssignment.first(:conditions => ["assignment_id = ? AND user_id = ?", params[:assignment_id], current_user.id])
          elsif assignment.type_assignment == Group_Activity
            send_assignment = SendAssignment.first(:conditions => ["assignment_id = ? AND group_assignment_id = ?", params[:assignment_id], params[:group_assignment_id]])
          end
          send_assignment_id = send_assignment.nil? ? nil : send_assignment[:id] # verificando se ja existe um id para setar na tabela de arquivos

          # se nao existir id criado no send_assignment, devera ser criado
          if send_assignment_id.nil?
            send_assignment = SendAssignment.new do |sa|
              sa.assignment_id = params[:assignment_id]
              sa.user_id = current_user.id unless !params[:group_assignment_id].nil?
              sa.group_assignment_id = params[:group_assignment_id]
            end

            send_assignment.save!
          end

          # salvando arquivos na base de dados
          assignment_file = AssignmentFile.new params[:assignment_file]
          assignment_file.send_assignment_id = send_assignment.id
          assignment_file.user_id = current_user.id
          assignment_file.save!

          flash[:notice] = t(:file_uploaded)
          format.html { redirect_to(redirect) }
        rescue Exception => error
          flash[:alert] = error.message
          format.html { redirect_to(redirect) }
        end
      end
    else
      no_permission_redirect
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

    # verificação se o arquivo individual é dele ou se faz parte do grupo
    individual_activity_or_part_of_group = Portfolio.verify_student_individual_activity_or_part_of_the_group(assignment_id, current_user.id, file_id)
    
    if individual_activity_or_part_of_group
      download_file({:action => 'activity_details', :id => assignment_id}, AssignmentFile.find(file_id).attachment.path)
    else
      no_permission_redirect
    end
  end

  #Formulário de upload exibido numa lightbox
  def public_files_send
    render :layout => false
  end

end