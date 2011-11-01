################################################################################
# obs: o controle de acesso é feito individualmente em cada action por se tratar
# de um controller fora dos padroes
################################################################################

include FilesHelper

class PortfolioController < ApplicationController

  before_filter :require_user
  before_filter :prepare_for_group_selection, :only => [:list]

  # Lista as atividades
  def list

    authorize! :list, Portfolio

    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # listando atividades individuais pelo grupo_id em que o usuario esta inserido
    @individual_activities = Portfolio.individual_activities(group_id, current_user.id)

    # area publica
    @public_area = Portfolio.public_area(group_id, current_user.id)

  end

  # Recupera as informacoes de uma atividade - lista arquivos enviados e opcao para enviar arquivos
  def activity_details

    authorize! :activity_details, Portfolio

    assignment_id = params[:id]

    # recupera a atividade selecionada
    @activity = Portfolio.find(assignment_id, :joins => :schedule)

    # verifica se os arquivos podem ser deletados
    @delete_files = verify_date_range(@activity.schedule.start_date.to_time, @activity.schedule.end_date.to_time, Time.now)

    # recuperar o send_assignment
    student_id = current_user.id

    # recupera os arquivos enviados pelo aluno
    send_assignment = Portfolio.assignments_student(student_id, assignment_id)

    @grade = nil # nota dada pelo professor a atividade enviada
    @comment = nil # comentario do professor
    @files_sent = [] # arquivos enviados pelo aluno
    @files_comments = [] # arquivos dos comentarios enviados pelo professor

    # verifica se o aluno respondeu a atividade
    unless send_assignment.first.nil?

      # recupera o primeiro registro
      send_assignment = send_assignment.first

      # nota
      @grade = send_assignment.grade

      # listagem de arquivos enviados pelo aluno para a atividade
      @files_sent = AssignmentFile.where(["send_assignment_id = ?", send_assignment.id])

      # comentarios do professor com informacoes de arquivos para download
      comment = AssignmentComment.find_by_send_assignment_id(send_assignment.id)

      unless comment.nil?
        # comentario do professor
        @comment = comment.comment

        # arquivos enviados pelo professor para este comentario
        @files_comments = CommentFile.all(:conditions => ["assignment_comment_id = ?", comment.id])
      end

    end

    @situation = Assignment.status_of_actitivy_by_assignment_id_and_student_id(assignment_id, student_id)

  end

  # Delecao de arquivos da area individual
  def delete_file_individual_area

    authorize! :delete_file_individual_area, Portfolio

    assignment_id = params[:assignment_id]
    redirect = {
      :controller => :portfolio,
      :action => :activity_details,
      :id => assignment_id
    }

    respond_to do |format|

      begin

        # verifica periodo para delecao das atividades
        assignment = Portfolio.find(assignment_id)
        start_date = assignment.schedule.start_date
        end_date = assignment.schedule.end_date

        # verifica permissao de intervalo de datas para deletar arquivos
        raise t(:delete_file_interval_error) unless verify_date_range(start_date.to_time, end_date.to_time, Time.now)

        assignment_file_id = params[:id]

        # recupera o nome do arquivo a ser feito o download
        filename = AssignmentFile.find(assignment_file_id).attachment_file_name

        # arquivo a ser deletado
        file_del = "#{::Rails.root.to_s}/media/portfolio/individual_area/#{assignment_file_id}_#{filename}"
        error = false

        # deletar o arquivo da base de dados
        error = true unless AssignmentFile.find(assignment_file_id).delete

        # deletar o arquivo do servidor
        unless error
          File.delete(file_del) if File.exist?(file_del)

          flash[:success] = t(:file_deleted)
          format.html { redirect_to(redirect) }

        else
          raise t(:error_delete_file)
        end

      rescue Exception

        flash[:error] = t(:error_delete_file)
        format.html { redirect_to(redirect) }

      end

    end
  end

  # Download dos arquivos do comentario do professor
  def download_file_comment

    authorize! :download_file_comment, Portfolio

    comment_file_id = params[:id]

    begin
      file_ = CommentFile.find(comment_file_id)

      assignment_comment_id = file_.assignment_comment_id
      filename = file_.attachment_file_name

      prefix_file = file_.id # id da tabela comment_file para diferenciar os arquivos
      path_file = "#{::Rails.root.to_s}/media/portfolio/comments/"

      # id da atividade
      send_assignment = SendAssignment.joins(:assignment_comments).where(["assignment_comments.id = ?", assignment_comment_id])

      # verifica se foi encontrado algum registro
      if send_assignment.length > 0
        assignment_id = send_assignment.first.assignment_id
        redirect_error = {:action => :activity_details, :id => assignment_id}
      else

        curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
        # redireciona para a pagina de listagem de atividades
        redirect_error = {:action => :list, :id => curriculum_unit_id}

      end

      # recupera arquivo
      download_file(redirect_error, path_file, filename, prefix_file)

    rescue
      flash[:error] = flash[:error] = t(:error_nonexistent_file)
      redirect_to({:controller => :users, :action => :mysolar})
    end

  end

  ##################
  #  AREA PUBLICA
  ##################

  # Envio de arquivos para a area publica
  def upload_files_public_area

    authorize! :upload_files_public_area, Portfolio

    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => :list, :id => params[:curriculum_unit_id]}

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:portfolio)

        # allocation_tag do grupo selecionada
        allocation_tag_id = AllocationTag.find(:first, :conditions => ["group_id = ?", session[:opened_tabs][session[:active_tab]]["groups_id"]]).id


        @public_file = PublicFile.new params[:portfolio]
        @public_file.user_id = current_user.id
        @public_file.allocation_tag_id = allocation_tag_id
        @public_file.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error

        flash[:error] = error.message # @public_file.errors.full_messages
        format.html { redirect_to(redirect) }

      end
    end
  end

  # Delecao de arquivos da area publica
  def delete_file_public_area

    authorize! :delete_file_public_area, Portfolio

    # unidade curricular
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
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

          flash[:success] = t(:file_deleted)
          format.html { redirect_to(redirect) }
          
        else
          raise t(:error_delete_file) unless error == 0
        end

      rescue Exception
        flash[:success] = t(:error_delete_file)
        format.html { redirect_to(redirect) }
      end

    end
  end

  # Download dos arquivos da area publica
  def download_file_public_area

    authorize! :download_file_public_area, Portfolio

    filename = PublicFile.find(params[:id]).attachment_file_name
    prefix_file = params[:id]
    path_file = "#{::Rails.root.to_s}/media/portfolio/public_area/"

    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}

    # recupera arquivo
    download_file(redirect_error, path_file, filename, prefix_file)

  end

  ####################
  #  AREA INDIVIDUAL
  ####################

  # Evio de arquivos como resposta para a atividade
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
          end

          # salvando atividade do aluno
          send_assignment.save!
        end

        # salvando arquivos na base de dados
        assignment_file = AssignmentFile.new params[:assignment_file]
        assignment_file.send_assignment_id = send_assignment.id
        assignment_file.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error

        flash[:error] = error.message
        format.html { redirect_to(redirect) }

      end
    end
  end

  # Download dos arquivos da area individual
  def download_file_individual_area

    authorize! :download_file_individual_area, Portfolio

    begin
      filename = AssignmentFile.find(params[:id]).attachment_file_name
      prefix_file = params[:id]
      path_file = "#{::Rails.root.to_s}/media/portfolio/individual_area/"

      # id da atividade
      id = SendAssignment.find(AssignmentFile.find(params[:id]).send_assignment_id).assignment_id

      # modificar id
      redirect_error = {:action => 'activity_details', :id => id}

      # recupera arquivo
      download_file(redirect_error, path_file, filename, prefix_file)

    rescue
      flash[:error] = flash[:error] = t(:error_nonexistent_file)
      redirect_to({:controller => :users, :action => :mysolar})
    end

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



