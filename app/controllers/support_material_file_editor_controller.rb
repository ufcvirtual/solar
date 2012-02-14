class SupportMaterialFileEditorController < ApplicationController

  def list

    # Recuperando os arquivos enviados do material de apoio

    #################  OBTER OS ARQUIVOS COM OS QUAIS O EDITOR FEZ O UPLOAD  ##################
    @select_curriculum_editor = SupportMaterialFileEditor.select_every_curriculum(current_user.id)
    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id']
    @list_files = SupportMaterialFile.search_files(allocation_tag_id)
    curriculum_unit_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['id'] #user_session[:tabs][:opened][user_session[:tabs][:active]]

    # construindo um conjunto de objetos
    @folders_list = {}
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
    @list_pastes = SupportMaterialFileEditor.list_pastes(current_user.id)

    @list_temp = []
    name_iqual =false
    @list_pastes.flatten.each do |name|
      @list_temp.each do |test|
        if test == name['folder']
          name_iqual = true
          break
        end
      end
      @list_temp << name['folder'] if !name_iqual
      name_iqual = false
    end

    # lista para o 'select' versão 2.0
    @select_options_editor = SupportMaterialFileEditor.select_unit_editor(user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'])

    # As variáveis comentadas a seguir serão necessárias caso o menu esteja dentro do Curriculum Unit
    @editor_curriculum_unit = []
    @editor_group = []
  end

  def upload_link
    url  = params[:link]["link"]

    if (url.empty?)
      flash[:error] = "Link deve ser preenchido !"
      redirect_to :controller => "support_material_file_editor", :action => "list"
      return
    end

    allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id],params[:type_for_allocation_tag_id])

    SupportMaterialFile.upload_link(allocation_tag_id, url)

    flash[:success] = "Link enviado com sucesso!"
    redirect_to :controller => "support_material_file_editor", :action => "list"

  end

  def edit_link
    raise "para implementar"
  end

  def upload_files
    #    authorize! :upload_files, SupportMaterialFileEditor

    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => :list}

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:support_material)

        # verifica se é uma pasta existente no banco ou uma nova criado pelo usuário.
        if (params[:support_material][:new_folder] != "")
          params[:support_material][:folder] = params[:support_material][:new_folder]
        end

        params[:support_material].delete(:new_folder)

        # verifica se o arquivo enviado já existe na pasta selecionada
        file = SupportMaterialFile.new params[:support_material]

        # Se retornar um registro é porque já existe no banco e nao pode inserir, se for vazio pode inserir
        verify = SupportMaterialFile.find_by_attachment_file_name_and_folder_and_allocation_tag_id(file.attachment_file_name, file.folder.upcase.strip, file.allocation_tag_id)

        raise "Arquivo escolhido existe nessa mesma pasta !" unless (verify.nil?)
        
        allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id],params[:type_for_allocation_tag_id])

        @file = SupportMaterialFile.new params[:support_material]
        @file.folder = @file.folder.upcase.strip
        @file.allocation_tag_id = allocation_tag_id
        @file.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error
        flash[:error] = error.message
        format.html { redirect_to(redirect) }
      end
    end
  end

  def upload_general_paste
    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => :list}

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:support_material)

        params[:support_material][:folder] = "Geral"

        # verifica se o arquivo enviado ja existe na pasta selecionada
        file = SupportMaterialFile.new params[:support_material]

        # Se retornar um registro é porque já existe no banco e nao pode inserir, se for vazio pode inserir
        verify = SupportMaterialFile.find_by_attachment_file_name_and_folder_and_allocation_tag_id(file.attachment_file_name, file.folder.upcase.strip, file.allocation_tag_id)

        raise "Arquivo escolhido existe nessa mesma pasta !" unless (verify.nil?)

        allocation_tag_id = allocation_tag_choosed(params[:value_for_allocation_tag_id],params[:type_for_allocation_tag_id])

        @file = SupportMaterialFile.new params[:support_material]
        @file.folder = @file.folder.upcase.strip
        @file.allocation_tag_id = allocation_tag_id
        @file.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error
        flash[:error] = error.message
        format.html { redirect_to(redirect) }
      end
    end
  end
  
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

  #Deleta arquivos e links
  def delete_select_file
    #    authorize! :delete_file_public_area, Portfolio
    redirect = {:action => :list}
    respond_to do |format|
      begin
        # arquivo a ser deletado
        file_del = "#{::Rails.root.to_s}/media/support_material_file/#{params[:id]}_#{SupportMaterialFile.find(params[:id]).attachment_file_name}"

        error = false

        # deletar arquivo da base de dados
        error = true unless SupportMaterialFile.find(params[:id]).delete

        # deletar arquivo do servidor
        unless error
          File.delete(file_del) if File.exist?(file_del)

          flash[:success] = t(:file_deleted)
          format.html { redirect_to(redirect) }
        else
          raise t(:error_delete_file) unless !error
        end

      rescue Exception
        flash[:error] = t(:error_delete_file)
        format.html { redirect_to(redirect) }
      end
    end
  end

end
