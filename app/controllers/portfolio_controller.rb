################################################################################
# obs: o controle de acesso é feito individualmente em cada action por se tratar
# de um controller fora dos padroes
################################################################################

class PortfolioController < ApplicationController

  before_filter :require_user
  before_filter :curriculum_unit_name, :only => [:list, :activity_details]

  # lista as atividades
  def list

    authorize! :list, Portfolio

    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # listando atividades individuais pelo grupo_id em que o usuario esta inserido
    @individual_activities = individual_activities(group_id, current_user.id)

    # area publica
    @public_area = public_area(group_id, current_user.id)

  end

  # recupera as informacoes de uma atividade - lista arquivos enviados e opcao para enviar arquivos
  def activity_details

    authorize! :activity_details, Portfolio

    assignment_id = params[:id]

    # recupera a atividade selecionada
    @activity = Assignment.joins(:allocation_tag).where(["assignments.id = ?", assignment_id]).first

    # recuperar o send_assignment
    send_assignment = SendAssignment.where(["assignment_id = ? AND user_id = ?", assignment_id, current_user.id])

    @correction = nil # indica se a atividade do aluno foi corrigida ou nao
    @grade = nil # nota dada pelo professor a atividade enviada
    @comment = nil # comentario do professor
    @files_sent = [] # arquivos enviados pelo aluno
    @files_comments = [] # arquivos dos comentarios enviados pelo professor

    # verifica se o aluno respondeu a atividade
    unless send_assignment.first.nil?

      # recupera o primeiro registro
      send_assignment = send_assignment.first

      # verifica se a nota foi dada, caso verdadeiro a atividade foi corrigida pelo professor
      @correction = (send_assignment.grade != nil) ? 'corrected' : 'sent'

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

    else
      # arquivos ainda nao enviados pelo aluno
      @correction = 'send'
    end

  end

  # delecao de arquivos da area publica
  def delete_file_individual_area

    authorize! :delete_file_individual_area, Portfolio

    redirect = {:action => "activity_details", :id => params[:assignment_id]} # modificar esse id

    respond_to do |format|

      begin

        assignment_file_id = params[:id]

        # recupera o nome do arquivo a ser feito o download
        filename = AssignmentFile.find(assignment_file_id).attachment_file_name

        # arquivo a ser deletado
        file_del = "#{::Rails.root.to_s}/media/portfolio/individual_area/#{params[:id]}_#{filename}"
        error = 0

        # verificando se o arquivo ainda existe
        if File.exist?(file_del)

          # deleta o arquivo do servidor
          if File.delete(file_del)

            # retira o registro da base de dados
            if AssignmentFile.find(params[:id]).delete

              flash[:success] = t(:file_deleted)
              format.html { redirect_to(redirect) }

            end
          else
            error = 1 # arquivo nao deletado
          end

        else
          error = 1 # arquivo inexistente
        end

        raise t(:error_delete_file) unless error == 0

      rescue Exception => except

        flash[:error] = except
        format.html { redirect_to(redirect) }

      end

    end
  end

  # delecao de arquivos da area publica
  def delete_file_public_area

    authorize! :delete_file_public_area, Portfolio

    # unidade curricular
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
    redirect = {:action => "list", :id => curriculum_unit_id}

    respond_to do |format|

      begin

        # arquivo a ser deletado
        file_name = PublicFile.find(params[:id]).attachment_file_name
        file_del = "#{::Rails.root.to_s}/media/portfolio/public_area/#{params[:id]}_#{file_name}"

        error = 0

        # verificando se o arquivo ainda existe
        if File.exist?(file_del)

          # deleta o arquivo do servidor
          if File.delete(file_del)

            # retira o registro da base de dados
            if PublicFile.find(params[:id]).delete

              flash[:success] = t(:file_deleted)
              format.html { redirect_to(redirect) }

            end
          else
            error = 1 # arquivo nao deletado
          end

        else
          error = 1 # arquivo inexistente
        end

        raise t(:error_delete_file) unless error == 0

      rescue Exception => except
        flash[:success] = except
        format.html { redirect_to(redirect) }
      end

    end
  end

  # download dos arquivos do comentario do professor
  def download_file_comment

    authorize! :download_file_comment, Portfolio

    comment_file_id = params[:id]

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
      redirect_error = {:action => 'activity_details', :id => assignment_id}
    else

      curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
      # redireciona para a pagina de listagem de atividades
      redirect_error = {:action => 'list', :id => curriculum_unit_id}

    end

    # recupera arquivo
    download_file(redirect_error, path_file, filename, prefix_file)

  end

  ##################
  #  AREA PUBLICA
  ##################

  # envio de arquivos para a area publica
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

  # download dos arquivos da area publica
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

  # envio de arquivos como resposta para a atividade
  def upload_files_individual_area

    authorize! :upload_files_individual_area, Portfolio

    respond_to do |format|
      begin

        # redireciona para os detalhes da atividade individual
        redirect = {:action => :activity_details, :id => params[:assignment_id]}

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

  # download dos arquivos da area individual
  def download_file_individual_area

    authorize! :download_file_individual_area, Portfolio

    filename = AssignmentFile.find(params[:id]).attachment_file_name
    prefix_file = params[:id]
    path_file = "#{::Rails.root.to_s}/media/portfolio/individual_area/"

    # id da atividade
    id = SendAssignment.find(AssignmentFile.find(params[:id]).send_assignment_id).assignment_id

    # modificar id
    redirect_error = {:action => 'activity_details', :id => id}

    # recupera arquivo
    download_file(redirect_error, path_file, filename, prefix_file)

  end

  ###################
  # Funcoes privadas
  ###################

  private

  # recupera o nome do curriculum_unit
  def curriculum_unit_name
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"] # recupera unidade curricular da sessao
    @curriculum_unit = CurriculumUnit.select("id, name").where(["id = ?", curriculum_unit_id]).first
  end

  # atividades individuais
  def individual_activities(group_id, user_id)

    ia = ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.id,
           t1.name,
           t1.enunciation,
           t1.start_date,
           t1.end_date,
           t2.grade,
           COUNT(t3.id) AS comments,
           CASE
            WHEN t2.grade IS NOT NULL THEN 'corrected'
            WHEN t2.id IS NOT NULL    THEN 'sent'
            WHEN t2.id IS NULL        THEN 'send'
           END AS correction
      FROM assignments         AS t1
      JOIN allocation_tags     AS t4 ON t4.id = t1.allocation_tag_id
      JOIN allocations         AS t5 ON t5.allocation_tag_id = t4.id
 LEFT JOIN send_assignments    AS t2 ON t2.assignment_id = t1.id
 LEFT JOIN assignment_comments AS t3 ON t3.send_assignment_id = t2.id
     WHERE t4.group_id = #{group_id}
       AND t5.user_id = #{user_id}
  GROUP BY t1.id, t2.id, t1.name, t1.enunciation, t1.start_date, t1.end_date, t2.grade
  ORDER BY t1.end_date, t1.start_date DESC;
SQL

    return (ia.nil?) ? [] : ia

  end

  # arquivos da area publica
  def public_area(group_id, user_id)

    pa = ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.id,
           t1.attachment_file_name,
           t1.attachment_content_type,
           t1.attachment_file_size
      FROM public_files AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN users AS t3 ON t3.id = t1.user_id
     WHERE t3.id = #{user_id}
       AND t2.group_id = #{group_id};
SQL

    return (pa.nil?) ? [] : pa

  end

end
