class SupportMaterialFilesController < ApplicationController

  include FilesHelper

  layout false, :except => [:index]
  before_filter :prepare_for_group_selection, :only => [:index]

  def index
    authorize! :index, SupportMaterialFile

    @allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    @list_files = SupportMaterialFile.find_files(@allocation_tag_ids)

    @folders_list = {}
    @list_files.collect { |file|
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array) # utiliza nome do folder como chave da lista
      @folders_list[file["folder"]] << file
    }
  end

  def new
    @allocation_tags_ids = params[:allocation_tags_ids].uniq
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids

    @support_material = SupportMaterialFile.new material_type: params[:material_type]
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids

    begin
      raise "mais de uma allocation_tag" if @allocation_tags_ids.count > 1 # trabalha apenas para uma allocation tag

      @support_material = SupportMaterialFile.new(params[:support_material_file])
      @support_material.material_type = params[:material_type]
      @support_material.folder = (params[:material_type] == 'url') ? 'LINKS' : 'GERAL'
      @support_material.allocation_tag_id = @allocation_tags_ids.first.to_i
      @support_material.attachment_updated_at = Time.now
      @support_material.save!

      render nothing: true
    rescue
      render :new
    end

  end

  def destroy
    authorize! :destroy, SupportMaterialFile, on: params[:allocation_tags_ids].split(" ")

    begin
      SupportMaterialFile.transaction do
        SupportMaterialFile.where(id: params[:id].split(",")).map(&:destroy)
      end
      render json: {success: true}
    rescue Exception => e
      render json: {success: false, msg: e.messages}, status: :unprocessable_entity
    end
  end

  def download
    authorize! :download, SupportMaterialFile

    if params.include?(:type)
      allocation_tag_ids = params[:allocation_tag_id].split(',').map(&:to_i)
      redirect_error = support_material_files_path

      all_files = case params[:type]
      when 'all'
        SupportMaterialFile.find_files(allocation_tag_ids)
      when 'url'
        SupportMaterialFile.find_files(allocation_tag_ids, params[:folder])
      end

      path_zip = compress({ files: all_files, table_column_name: 'attachment_file_name', name_zip_file: t(:support_folder_name) })
      download_file(redirect_error, path_zip)
    else
      file = SupportMaterialFile.find(params[:id])
      download_file(support_material_files_path, file.attachment.path, file.attachment_file_name)
    end

  end

  def list
    @what_was_selected = params[:what_was_selected]
    # @allocation_tags_ids = params[:allocation_tags_ids].uniq
    allocation_tags = params[:allocation_tags_ids].uniq

    begin

      authorize! :list, SupportMaterialFile, on: allocation_tags
      @materials = SupportMaterialFile.where(allocation_tag_id: allocation_tags)
      @allocation_tags = AllocationTag.find(allocation_tags)

    rescue Exception => error
      respond_to do |format|
        format.html { render :nothing => true, :status => 500  }
      end
    end

    # raise "#{@allocation_tags}"
  end


  # seleciona o upload_link() ou delete_select_file(), somente para links
  # def select_action_link
  #   if params[:commit] == t(:support_delete) 
  #     list_checked_links = create_list_checked_itens('LINKS', params[:list_check_file])
  #     delete_select(list_checked_links)
  #   elsif params[:commit] == t(:support_add)
  #     upload_link(params[:form][:link], params[:value_for_allocation_tag_id], params[:type_for_allocation_tag_id])
  #   end
  # end

  # seleciona o upload_file() ou delete_select_file(), para as pastas que não de links / renomeia a pasta
  # def select_action_file
  #   # se estiver deletando um arquivo
  #   if params[:commit] == t(:support_delete)
  #     list_checked_files = create_list_checked_itens(params[:folder_name].tr(' ', ''), params[:list_check_file])
  #     delete_select(list_checked_files)
  #   # se estiver enviando um arquivo
  #   elsif params[:commit] == t(:send)
  #     # verifica se os parâmetros existem; caso contrário, o usuário não colocou nenhum arquivo
  #     file_uploaded = true if params.include?(:support_material)
  #     upload_files(params[:folder_name], file_uploaded, params[:support_material], params[:value_for_allocation_tag_id], params[:type_for_allocation_tag_id])
  #   # se for pra renomear uma pasta
  #   elsif params[:commit] == t(:support_rename)
  #     # se não tiver alterado nada
  #     if params[:folder_name] == params[:new_folder_name].upcase
  #       error_message = "same_name"
  #     # se alterou
  #     else
  #       # verifica se houve algum erro
  #       error_message = verify_errors_folder(params[:new_folder_name].upcase, params[:folders_list])
  #     end
  #     # não houve erro
  #     if error_message == ""
  #       flash[:notice] = t(:support_folder_renamed)
  #       allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id], params[:type_for_allocation_tag_id])
  #       # recupera todos os arquivos da pasta renomeada considerando o allocation_tag
  #       files_folder = SupportMaterialFile.find_all_by_folder_and_allocation_tag_id(params[:folder_name], allocation_tag_id)
  #       # altera o nome da pasta dos arquivos da pasta em questão
  #       for file in files_folder
  #         file.update_attribute('folder', params[:new_folder_name].upcase)
  #       end
  #     # não alterou nome
  #     elsif error_message == "same_name"
  #       flash[:alert] = t(:support_no_changes)
  #     else
  #       flash[:alert] = error_message
  #     end
  #     redirect_to :action => "list_edition"
  #   end
  # end

  # Método que verifica se a pasta a ser criada já existe e que redireciona seus valores para que o usuário possa fazer o upload de arquivos para
  # salvar efetivamente a pasta
  # def folder_verify
  #     # verifica possíveis erros na criação da pasta
  #     error_message = verify_errors_folder(params[:support_material][:folder_name].upcase, params[:folders_list])
  #     # não houve erro
  #     if error_message == ""
  #       flash[:notice] = t(:support_folder_temporary_message)
  #       redirect_to :action => :list_edition, :folder_temp => params[:support_material][:folder_name]
  #     # houve erro
  #     else
  #       flash[:alert] = error_message
  #       redirect_to :action => :list_edition
  #     end
  # end

  # excluir uma pasta para determinado "allocation_tag"
  # def delete_folder
  #   allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id],params[:type_for_allocation_tag_id])
  #   all_files_folder = SupportMaterialFile.find_all_by_folder_and_allocation_tag_id(params[:folder_name], allocation_tag_id)
  #   unless all_files_folder.empty?
  #     for file in all_files_folder
  #       file.destroy
  #     end
  #   end
  #   redirect_to :action => :list_edition
  # end

  private

  ##
  # Método que cria a lista com os ids dos arquivos de uma determinada pasta (utilizado pelo select_action_link e _file)
  #
  # Parameters:
  # - folder: pasta que teve a "ação"
  # - selected_itens: recupera todos os ids dos itens selecionados de determinada pasta
  ##
  # def create_list_checked_itens(folder, selected_itens)
  #    list_checked_itens = []
  #    # a menos que nenhum item tenha sido selecionado
  #     unless selected_itens.nil?
  #       # selected itens vem no formato: [{"pasta"=>"id do item checado"}]
  #       # logo, o collect abaixo pega o valor do id do item checado associado à pasta que realizou o "commit"
  #       list_checked_itens = selected_itens.collect{|item| item[folder] }
  #     end
  #     # retorna uma lista de ids referentes aos checkbox marcados na página
  #     return list_checked_itens
  # end

  ##
  # Método que adiciona um link
  #
  # Parameters:
  # - url: link digitado
  # - id_of_choosen_type: id da unidade, oferta ou turma escolhida
  # - type_is_curriculum_unit_or_offer_or_group: recebe uma string que indica o que foi selecionado no elemento de navegação de
  # alocação superior
  ##
  # def upload_link(url, id_of_choosen_type, type_is_curriculum_unit_or_offer_or_group)
  #   # se o usuário tiver clicado em 'adicionar' com o link com a mensagem padrão ou vazio
  #   if (url.blank? or url == t(:support_text_field_link))
  #     flash[:alert] = t(:support_error_missing_link)
  #   else
  #     allocation_tag_id = allocation_tag_choosed(value_for_allocation_tag_id,type_for_allocation_tag_id)
  #     SupportMaterialFile.upload_link(allocation_tag_id, url)
  #     flash[:notice] = t(:support_sent_link)
  #   end
  #   redirect_to :action => :list_edition
  # end

  ##
  # Método que verifica se o nome da pasta já existe ou se está em branco. Este método retorna a mensagem de erro, caso exista.
  #
  # Parameters:
  # - folder_name: nome da pasta que está sendo acessada
  # - list_all_folders: lista de todas as pastas existentes no formato: {"nome da pasta"=>["id de um arquivo"]}
  ##
  # def verify_errors_folder(folder_name, list_all_folders)
  #     error_saving_folder = false 
  #     # se o nome da nova pasta for inválido (vazio ou igual à "GERAL" ou "LINKS"), guarda o erro
  #     if folder_name == "GERAL" or folder_name == "LINKS" or folder_name.blank?
  #       error_saving_folder = true
  #     else
  #       unless list_all_folders.nil?
  #         # list_all_folders está no formato: {"nome da pasta"=>["id de um arquivo"]}
  #         # então, a lista list_all_folders_names recupera apenas o nome de cada pasta
  #         list_all_folders_names = list_all_folders.collect{ |folder| folder[0] }
  #         # se o nome escolhido para a nova pasta, já estiver sendo usado, guarda um erro
  #         error_saving_folder = true if list_all_folders_names.include?(folder_name)
  #       end
  #     end

  #      if error_saving_folder == false
  #        error_message = ""
  #      elsif folder_name.blank?
  #       error_message = t(:support_error_missing_folder)
  #      else
  #        error_message = t(:support_error_existing_folder)
  #      end

  #      # já retorna a mensagem para o erro específico, caso tenha ocorrido
  #     return error_message
  # end

  ##
  # Upload de arquivos
  #
  # Parameters:
  # - folder_name: nome da pasta a que está se adicionando o arquivo
  # - file_uploaded: boolean que indica se foi enviado algum arquivo ou não
  # - support_material_params: recebe os valores do material de apoio, que, no caso, é apenas o arquivo em si
  # - id_of_choosen_type: id da unidade, oferta ou turma escolhida
  # - type_is_curriculum_unit_or_offer_or_group: recebe uma string que indica o que foi selecionado no elemento de navegação de
  # alocação superior
  ##
  # def upload_files(folder_name, file_uploaded, support_material_params, id_of_choosen_type, type_is_curriculum_unit_or_offer_or_group)
  #   respond_to do |format|
  #     begin
  #       # redireciona para a lista
  #       redirect = {:action => :list_edition}
  #       # define a allocation_tag a partir do selecionado no elemento superior de navegação 
  #       #(escolha de unidade, oferta e turma).
  #       allocation_tag_id = allocation_tag_choosed(id_of_choosen_type, type_is_curriculum_unit_or_offer_or_group)

  #       # verifica se o arquivo foi adicionado
  #       raise t(:support_material_error_no_file_sent) unless file_uploaded

  #       # verifica se o arquivo enviado já existe na pasta selecionada
  #       file = SupportMaterialFile.new(support_material_params)
  #       file.folder = folder_name.upcase
  #       file.allocation_tag_id = allocation_tag_id

  #       ##################################################
  #       ## Parece que esta verificação não é necessária ##
  #       ##################################################
  #       # Se retornar um registro é porque já existe no banco e nao pode inserir, se for vazio pode inserir
  #       file_already_exists = SupportMaterialFile.find_by_attachment_file_name_and_folder_and_allocation_tag_id(file.attachment_file_name, file.folder, file.allocation_tag_id)
  #       raise t(:support_error_existing_file) unless (file_already_exists.nil?)
  #       ##################################################
  #       ## Parece que esta verificação não é necessária ##
  #       ##################################################

  #       # realiza o upload de um novo arquivo
  #       file.save!

  #       # arquivo salvo com sucesso
  #       flash[:notice] = t(:support_material_file_uploaded)
  #     rescue Exception => error
  #       flash[:alert] = error.message
  #     end
  #     format.html { redirect_to(redirect) }
  #   end
  # end

  ##
  # Metodo auxiliar que localiza allocation_tag atual, e uma funcao auxiliar que e chamado varias vezes ao longo do codigos
  #
  # Parameters:
  # - value: recebe o id do tipo indicado por 'type'
  # - type: recebe uma string que indica se é 'curriculum_unit', 'offer' ou 'group'
  ##
  # def allocation_tag_choosed(value, type)
    
  #       # allocation_tag_id selecionada pela sessao do usuario
  #       allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] #@editor_general_data["allocation_tag_id"].to_i

  #       # allocation_tag_id recebe parametro do id da unidade curricular se esta existir e os demais nao
  #       allocation_tag_id = AllocationTag.find_all_by_curriculum_unit_id(value)[0].id if type == 'curriculum_unit'

  #       # allocation_tag_id recebe parametro do id da oferta se esta existir e o do grupo nao
  #       allocation_tag_id = AllocationTag.find_all_by_offer_id(value)[0].id if type == 'offer'
        
  #       # allocation_tag_id recebe parametro do id do grupo se este existir
  #       allocation_tag_id = AllocationTag.find_all_by_group_id(value)[0].id if type == 'group'

  #       return allocation_tag_id
  # end

  ##
  # Deleta arquivos e links selecionados
  #
  # Parameters:
  # - list_checked_itens: lista com os ids de cada item selecionado de determinada pasta
  # ##
  # def delete_select(list_checked_itens)
  #   # authorize! :delete_file_public_area, Portfolio
  #   redirect = {:action => :list_edition}
  #   respond_to do |format|
  #     begin
  #       # verifica se não foi selecionado nenhum checkbox  
  #       if list_checked_itens.empty?
  #         flash[:alert] = t(:support_error_no_item_selected)
  #       else
  #         list_checked_itens.each do |value_id|
  #           # arquivo a ser deletado
  #           deleting_file = File.join("#{::Rails.root.to_s}", "media", "support_material_file", "#{value_id}_#{SupportMaterialFile.find(value_id).attachment_file_name}")

  #           file_can_be_deleted = false

  #           # deletar arquivo da base de dados
  #           file_can_be_deleted = true unless SupportMaterialFile.find(value_id).delete

  #           # deletar arquivo do servidor
  #           unless file_can_be_deleted
  #             File.delete(deleting_file) if File.exist?(deleting_file)
  #             flash[:notice] = t(:support_material_file_deleted)
  #           else
  #             raise t(:support_material_error_delete_file)
  #           end
  #         end
  #       end
  #     rescue Exception
  #       flash[:alert] = t(:support_material_error_delete_file)
  #     end
  #     format.html { redirect_to(redirect) }
  #   end
  # end

end
