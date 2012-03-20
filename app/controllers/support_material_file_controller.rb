class SupportMaterialFileController < ApplicationController

  include FilesHelper

  before_filter :prepare_for_group_selection, :only => [:list_visualization]

  load_and_authorize_resource

  def list_visualization
    # authorize! :list_visualization, SupportMaterialFile

    allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    @list_files = SupportMaterialFile.find_files(allocation_tag_ids)

    # construindo um conjunto de objetos
    @folders_list = {}
    @list_files.collect { |file|
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array) # utiliza nome do folder como chave da lista
      @folders_list[file["folder"]] << file
    }
  end

  def download
    authorize! :download, SupportMaterialFile

    # redirect = "#{redirect_to :back}"
    # if redirect.include?("list_visualization")
    #   redirect = {:action => 'list_visualization', :id => curriculum_unit_id}
    # else
    #   redirect = {:action => 'list_edition', :id => curriculum_unit_id}
    # end


    curriculum_unit_id = active_tab[:url]['id']
    file = SupportMaterialFile.find(params[:id])
    download_file({:action => 'list_visualization', :id => curriculum_unit_id}, file.attachment.path, file.attachment_file_name)
  end

  def download_all_file_ziped
    authorize! :download_all_file_ziped, SupportMaterialFile

    allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    curriculum_unit_id = active_tab[:url]["id"]
    redirect_error = {:action => 'list_visualization', :id => curriculum_unit_id}

    # Recupearndo todos os arquivos e separando por folder
    all_files = SupportMaterialFile.find_files(allocation_tag_ids)
    path_zip = make_folders_zip(all_files, 'attachment_file_name', t(:support_folder_name))

    # download do zip
    download_file(redirect_error, path_zip)
  end

  def download_folder_file_ziped
    authorize! :download_folder_file_ziped, SupportMaterialFile

    allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    curriculum_unit_id = active_tab[:url]["id"]
    redirect_error = {:action => 'list_visualization', :id => curriculum_unit_id}
    
    all_files = SupportMaterialFile.find_files(allocation_tag_ids, params[:folder])
    path_zip = make_folders_zip(all_files, 'attachment_file_name', t(:support_folder_name))

    # download do zip
    download_file(redirect_error, path_zip)
  end
















  ################ editor

  def list_edition

    # Recuperando os arquivos enviados do material de apoio

    #################  OBTER OS ARQUIVOS COM OS QUAIS O EDITOR FEZ O UPLOAD  ##################
    @select_curriculum_editor = SupportMaterialFile.select_every_curriculum(current_user.id)
    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id']
    @list_files = SupportMaterialFile.search_files(allocation_tag_id)
    curriculum_unit_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['id'] #user_session[:tabs][:opened][user_session[:tabs][:active]]

    @folders_list = {}
    # cria uma lista de arquivos relacionados a uma chave "folder", por exemplo: {"pasta1"=>[#<arquivo 1>, #<arquivo 2>], "pasta2"=>[#<arquivo1>]}
    @list_files.collect {|file| 
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array)
      @folders_list[file["folder"]] << file
    }
    #######################################################
    ### Semestre mais atual, ou seja
    @semester_current = Offer.find_all_by_curriculum_unit_id(curriculum_unit_id)
    semester_temp = @semester_current[0].semester.to_f
    @semester_current.each do |f|
       semester_temp = f.semester.to_f if semester_temp < f.semester.to_f
    end
    @semester_current = semester_temp

    # Lista de pastas para o 'select'
    @list_pastes = SupportMaterialFile.list_folders(current_user.id)

    @list_temp = []
    @list_pastes.flatten.each do |name|
      @list_temp << name['folder'] unless @list_temp.include?(name['folder'])
    end

    # lista para o 'select' versão 2.0
    @select_options_editor = SupportMaterialFile.select_unit_editor(user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'])

    # As variáveis comentadas a seguir serão necessárias caso o menu esteja dentro do Curriculum Unit
    @editor_curriculum_unit = []
    @editor_group = []
  end

  # seleciona o upload_link() ou delete_select_file(), somente para links
  def select_action_link
    if params[:commit] == t(:support_delete) 
      list_checked_links = create_list_checked_itens('LINKS', params[:list_check_file])
      delete_select(list_checked_links)
    elsif params[:commit] == t(:support_add)
      upload_link(params[:form][:link], params[:value_for_allocation_tag_id], params[:type_for_allocation_tag_id])
    end
  end

  # seleciona o upload_file() ou delete_select_file(), para as pastas que não de links / renomeia a pasta
  def select_action_file
    # se estiver deletando um arquivo
    if params[:commit] == t(:support_delete)
      list_checked_files = create_list_checked_itens(params[:folder].tr(' ', ''), params[:list_check_file])
      delete_select(list_checked_files)
    # se estiver enviando um arquivo
    elsif params[:commit] == t(:send)
      # verifica se os parâmetros existem; caso contrário, o usuário não colocou nenhum arquivo
      file_uploaded = true if params.include?(:support_material)
      upload_files(params[:new_folder], params[:folder], file_uploaded, params[:support_material], params[:value_for_allocation_tag_id], params[:type_for_allocation_tag_id])
    # se for pra renomear uma pasta
    elsif params[:commit] == t(:support_rename)
      # se não tiver alterado nada
      if params[:folder] == params[:new_folder_name].upcase
        error_message = "same_name"
      # se alterou
      else
        # verifica se houve algum erro
        error_message = verify_errors_folder(params[:new_folder_name].upcase, params[:folders_list])
      end
      # não houve erro
      if error_message == ""
        flash[:success] = t(:support_folder_renamed)
        allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id], params[:type_for_allocation_tag_id])
        # recupera todos os arquivos da pasta renomeada considerando o allocation_tag
        files_folder = SupportMaterialFile.find_all_by_folder_and_allocation_tag_id(params[:folder], allocation_tag_id)
        # altera o nome da pasta dos arquivos da pasta em questão
        for file in files_folder
          file.update_attribute('folder', params[:new_folder_name].upcase)
        end
      # não alterou nome
      elsif error_message == "same_name"
        flash[:notice] = t(:support_no_changes)
      # houve erro
      else
        flash[:error] = error_message
      end
      redirect_to :action => "list_edition"
    end
  end

  # método que cria a lista com os ids dos arquivos de uma determinada pasta (utilizado pelo select_action_link e _file)
  def create_list_checked_itens(folder, selected_itens)
     list_checked_itens = []
     # a menos que nenhum item tenha sido selecionado
      unless selected_itens.nil?
        # selected itens vem no formato: [{"pasta"=>"id do item checado"}]
        # logo, o collect abaixo pega o valor do id do item checado associado à pasta que realizou o "commit"
        list_checked_itens = selected_itens.collect{|item| item[folder] }
      end
      # retorna uma lista de ids referentes aos checkbox marcados na página
      return list_checked_itens
  end

  # método que adiciona um link
  def upload_link(url, value_for_allocation_tag_id, type_for_allocation_tag_id)
    redirect = {:action => :list_edition}

    # se o usuário tiver clicado em 'adicionar' com o link com a mensagem padrão ou vazio
    if (url.empty? or url == t(:support_text_field_link))
      # exibe erro
      flash[:error] = t(:support_error_missing_link)
      redirect_to redirect
      # encerra método
      return
    end

    allocation_tag_id = allocation_tag_choosed(value_for_allocation_tag_id,type_for_allocation_tag_id)

    SupportMaterialFile.upload_link(allocation_tag_id, url)

    flash[:success] = t(:support_sent_link)
    redirect_to redirect
  end

  def edit_link
    raise "para implementar"
  end

  # Método que verifica se a pasta a ser criada já existe e que redireciona seus valores para que o usuário possa fazer o upload de arquivos para
  # salvar efetivamente a pasta
  def folder_verify
      begin
        # verifica possíveis erros na criação da pasta
        error_message = verify_errors_folder(params[:support_material][:new_folder].upcase, params[:folders_list])
        # não houve erro
         if error_message == ""
          flash[:notice] = t(:support_folder_temporary_message)
          redirect_to :action => :list_edition, :folder_temp => params[:support_material][:new_folder]
        # houve erro
         else
          flash[:error] = error_message
          redirect_to :action => :list_edition
         end
      end
  end

# Método que verifica se o nome da pasta já existe ou se está em branco. Este método retorna a mensagem de erro, caso exista.
  def verify_errors_folder(folder_name, list_all_folders)
      error_saving_folder = false 
      # se o nome da nova pasta for inválido (vazio ou igual à "GERAL" ou "LINKS"), guarda o erro
      if folder_name == "GERAL" or folder_name == "LINKS" or folder_name == ""
        error_saving_folder = true
      else
        unless list_all_folders.nil?
          # list_all_folders está no formato: {"nome da pasta"=>["id de um arquivo"]}
          # então, a lista list_all_folders_names recupera apenas o nome de cada pasta
          list_all_folders_names = list_all_folders.collect{ |folder| folder[0] }
          # se o nome escolhido para a nova pasta, já estiver sendo usado, guarda um erro
          error_saving_folder = true if list_all_folders_names.include?(folder_name)
        end
      end

       if error_saving_folder == false
         error_message = ""
       elsif folder_name == ""
        error_message = t(:support_error_missing_folder)
       else
         error_message = t(:support_error_existing_folder)
       end

      return error_message
  end

  # Upload de arquivos
  def upload_files(new_folder, folder, file_uploaded, support_material_params, value_for_allocation_tag_id, type_for_allocation_tag_id)
    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => :list_edition}

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless file_uploaded

        # verifica se é uma pasta existente no banco ou uma nova criado pelo usuário.
        if (!new_folder.blank?)
          folder = new_folder
        end

        # verifica se o arquivo enviado já existe na pasta selecionada
        file = SupportMaterialFile.new(support_material_params)
        file.folder = folder.upcase

        ##################################################
        ## Parece que esta verificação não é necessária ##
        ##################################################
        # Se retornar um registro é porque já existe no banco e nao pode inserir, se for vazio pode inserir
        file_already_exists = SupportMaterialFile.find_by_attachment_file_name_and_folder_and_allocation_tag_id(file.attachment_file_name, file.folder, file.allocation_tag_id)
        raise t(:support_error_existing_file) unless (file_already_exists.nil?)
        ##################################################
        ## Parece que esta verificação não é necessária ##
        ##################################################

        allocation_tag_id = allocation_tag_choosed(value_for_allocation_tag_id,type_for_allocation_tag_id)

        # realiza o upload de um novo arquivo
        file.allocation_tag_id = allocation_tag_id
        file.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
      rescue Exception => error
        flash[:error] = error.message
      end
      format.html { redirect_to(redirect) }
    end
  end

  # Metodo auxiliar que localiza allocation_tag atual, e uma funcao auxiliar que e chamado varias vezes ao longo do codigos
  def allocation_tag_choosed(value, type)
    
        # allocation_tag_id selecionada pela sessao do usuario
        allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] #@editor_general_data["allocation_tag_id"].to_i

        # allocation_tag_id recebe parametro do id da unidade curricular se esta existir e os demais nao
        allocation_tag_id = AllocationTag.find_all_by_curriculum_unit_id(value)[0].id if type == 'curriculum_unit'

        # allocation_tag_id recebe parametro do id da oferta se esta existir e o do grupo nao
        allocation_tag_id = AllocationTag.find_all_by_offer_id(value)[0].id if type == 'offer'
        
        # allocation_tag_id recebe parametro do id do grupo se este existir
        allocation_tag_id = AllocationTag.find_all_by_group_id(value)[0].id if type == 'group'

        return allocation_tag_id
  end

  # Deleta arquivos e links selecionados
  def delete_select(list_checked_itens)
    # authorize! :delete_file_public_area, Portfolio
    redirect = {:action => :list_edition}
    respond_to do |format|
      begin
        # verifica se não foi selecionado nenhum checkbox  
        if list_checked_itens.empty?
          flash[:error] = t(:support_error_no_item_selected)
        else
          list_checked_itens.each do |value_id|
            # arquivo a ser deletado
            deleting_file = File.join("#{::Rails.root.to_s}", "media", "support_material_file", "#{value_id}_#{SupportMaterialFile.find(value_id).attachment_file_name}")
            # deleting_file = "#{::Rails.root.to_s}/media/support_material_file/#{value_id}_#{SupportMaterialFile.find(value_id).attachment_file_name}"

            file_can_be_deleted = false

            # deletar arquivo da base de dados
            file_can_be_deleted = true unless SupportMaterialFile.find(value_id).delete

            # deletar arquivo do servidor
            unless file_can_be_deleted
              File.delete(deleting_file) if File.exist?(deleting_file)
              flash[:success] = t(:file_deleted)
            else
              raise t(:error_delete_file) if file_can_be_deleted
            end
          end
        end
      rescue Exception
            flash[:error] = t(:error_delete_file)
      end
      format.html { redirect_to(redirect) }
    end
  end

  # excluir uma pasta para determinado "allocation_tag"
  def delete_folder
    allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id],params[:type_for_allocation_tag_id])
    all_files_folder = SupportMaterialFile.find_all_by_folder_and_allocation_tag_id(params[:folder], allocation_tag_id)
    unless all_files_folder.empty?
      for file in all_files_folder
        file.destroy
      end
    end
    redirect_to :action => :list_edition
  end

#################### editor      


















private

  ##
  # Cria zip de arquivos com folders internos e retorna o path do zip
  #
  # Obs.: O zip será gerado com um hash. Se o um arquivo com um mesmo hash já existir ele não será criado, apenas o path será retornado.
  #
  # Parameters:
  # - table_column_name: Coluna da tabela que identifica o nome do arquivo.
  # - zip_name_folder: Nome do folder principal do zip. Se nao for informado os arquivos serão criados sem diretório.
  ##
  def make_folders_zip(files, table_column_name, zip_name_folder = nil)
    require 'zip/zip'

    all_file_names = files.collect{|file| [file[table_column_name]]}.flatten
    hash_name = Digest::SHA1.hexdigest(all_file_names.to_s)
    zip_name_folder = hash_name if zip_name_folder.nil?

    # hash que será usado como nome do arquivo zip
    all_files_ziped_name = File.join('tmp', "#{hash_name}.zip")

    ##
    # Verifica se já existe um arquivo zipado na tmp com o mesmo conteúdo.
    # Assim não será necessário recriar o zip, o usuário faz apenas download.
    ##
    existing_zip_files = Dir.glob('tmp/*') # lista dos arquivos .zip existentes no '/tmp'
    zip_created = existing_zip_files.include?(all_files_ziped_name) # informa se ja existe o arquivo de zip desejado
    name_internal_folder = ''

    # cria o zip caso nao esteja criado
    unless zip_created
      Zip::ZipFile.open(all_files_ziped_name, Zip::ZipFile::CREATE) { |zipfile|
        files.each do |file|
          unless file.attachment_file_name.nil?
            unless zip_created
              zipfile.mkdir(zip_name_folder) # cria folder geral para colocar todos os outros folders dentro dele
              zip_created = true
            end

            # cria um novo folder interno
            if name_internal_folder != file.folder and file.folder != ''
              name_internal_folder = file.folder
              zipfile.mkdir(File.join(zip_name_folder, name_internal_folder))
            end

            zipfile.add(File.join(zip_name_folder, name_internal_folder, file.attachment_file_name), file.attachment.path) if File.exists?(file.attachment.path.to_s)
          end
        end
      }
    end

    # recupera arquivo
    zip_name = Zip::ZipFile.open(hash_name + ".zip", Zip::ZipFile::CREATE).to_s
    path_zip = File.join(Rails.root.to_s, 'tmp', zip_name)
  end

end