class PortfolioController < ApplicationController

  before_filter :require_user

  #  load_and_authorize_resource

  def list
    @curriculum_unit = CurriculumUnit.find(params[:id])

    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    #    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    # atividades individuais
    # listando atividades individuais pelo grupo_id em que o usuario esta inserido
    @individual_activits = individual_activits(group_id, current_user.id)

    # area publica
    @public_area = public_area(group_id, current_user.id)

  end

  # envio de arquivos para o portfolio individual do aluno
  def upload_files

    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => "list", :id => params[:id]}

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

      rescue Exception => erro

        flash[:error] = erro.message # @public_file.errors.full_messages
        format.html { redirect_to(redirect) }

      end
    end

  end

  # download dos arquivos da area publica
  def download_file

    filename = PublicFile.find(params[:id]).attachment_file_name
    file_down = ::Rails.root.to_s + '/media/portfolio/public_area/' + params[:id] + '_' + filename

    if File.exist?(file_down)
      send_file file_down, :filename => filename#, :x_sendfile => true
    else

      respond_to do |format|
        flash[:success] = t(:error_nonexistent_file)
        format.html { redirect_to({:action => 'list', :id => 3}) }
      end

    end

  end

  # delecao de arquivos da area publica
  def delete_file

    redirect = {:action => "list", :id => 3}

    respond_to do |format|

      begin

        # arquivo a ser deletado
        file_del = ::Rails.root.to_s + '/media/portfolio/public_area/' + params[:id] + '_' + PublicFile.find(params[:id]).attachment_file_name

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
            raise "Arquivo nao deletado do servidor"
          end

        else
          raise "Arquivo nao econtrado no servidor"
        end

      rescue
        flash[:success] = t(:error_delete_file)
        format.html { redirect_to(redirect) }
      end

    end
  end

  private

  # atividades individuais
  def individual_activits(group_id, user_id)

    query = "
    SELECT t1.name,
           t1.enunciation,
           t1.initial_date,
           t1.final_date,
           COALESCE(t2.grade::text, '-') AS grade,
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
  GROUP BY t1.id, t2.id, t1.name, t1.enunciation, t1.initial_date, t1.final_date, t2.grade
  ORDER BY t1.final_date, t1.initial_date DESC;"

    ActiveRecord::Base.connection.select_all query

  end

  # arquivos da area publica
  def public_area(group_id, user_id)

    query = "
    SELECT t1.id,
           t1.attachment_file_name,
           t1.attachment_content_type,
           t1.attachment_file_size
      FROM public_files AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN users AS t3 ON t3.id = t1.user_id
     WHERE t3.id = #{user_id}
       AND t2.group_id = #{group_id};"

    ActiveRecord::Base.connection.select_all query

  end

end
