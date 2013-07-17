class SupportMaterialFilesController < ApplicationController

  include FilesHelper

  layout false, except: [:index]
  before_filter :prepare_for_group_selection, only: [:index]

  def index
    authorize! :index, SupportMaterialFile

    @allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url][:allocation_tag_id])
    @list_files = SupportMaterialFile.find_files(@allocation_tag_ids)

    @folders_list = {}
    @list_files.collect { |file|
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array) # utiliza nome do folder como chave da lista
      @folders_list[file["folder"]] << file
    }
  end

  def new
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids].uniq

    @support_material = SupportMaterialFile.new material_type: params[:material_type]
  end

  def create
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")

    begin
      @support_material = SupportMaterialFile.new(params[:support_material_file])
      @support_material.material_type = params[:material_type]
      @support_material.folder = (params[:material_type].to_i == Material_Type_Link) ? 'LINKS' : 'GERAL'
      @support_material.allocation_tag_id = @allocation_tags_ids.first.to_i  # o material é cadastrado apenas para uma allocation_tag
      @support_material.attachment_updated_at = Time.now
      @support_material.save!

      render nothing: true
    rescue
      if @support_material.is_link?
        render :new
      else
        render json: {success: false, msg: @support_material.errors.full_messages.join(' ')}, status: :unprocessable_entity
      end
    end
  end

  def edit
    authorize! :update, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids].uniq

    @support_material = SupportMaterialFile.find(params[:id])
  end

  def update
    @support_material = SupportMaterialFile.find(params[:id])
    authorize! :update, SupportMaterialFile, on: [params[:allocation_tags_ids]].flatten.uniq

    begin
      @support_material.update_attributes!(params[:support_material_file])
      render nothing: true
    rescue
      render :new
    end
  end

  def destroy
    authorize! :destroy, SupportMaterialFile, on: params[:allocation_tags_ids].uniq

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
    allocation_tag_ids = params.include?(:allocation_tag_id) ? params[:allocation_tag_id].split(",").map(&:to_i).uniq : [(file = SupportMaterialFile.find(params[:id])).allocation_tag_id]
    
    if params.include?(:type) # baixando alguma pasta ou todas

      # se quiser baixar os arquivos em um curso, basta ter permissão na turma
      groups = AllocationTag.where(id: allocation_tag_ids).map(&:group)
      authorize! :download, SupportMaterialFile, on: groups.compact.map(&:allocation_tag).map(&:id)

      redirect_error = support_material_files_path
      all_files = case params[:type]
      when :folder
        SupportMaterialFile.find_files(allocation_tag_ids, params[:folder])
      else
        SupportMaterialFile.find_files(allocation_tag_ids)
      end

      path_zip = compress({ files: all_files, table_column_name: 'attachment_file_name' })
      if(path_zip)
        download_file(redirect_error, path_zip)
      else
        redirect_to redirect_error, alert: t(:file_error_nonexistent_file)
      end
    else # baixando um arquivo individualmente

      # se for no cadastro de material de apoio ou um único arquivo, deve ter permissão em todas as allocation_tags (mesmo que seja apenas a do arquivo)
      authorize! :download, SupportMaterialFile, on: allocation_tag_ids

      file ||= SupportMaterialFile.find(params[:id])
      download_file(support_material_files_path, file.attachment.path, file.attachment_file_name)
    end
  end

  def list
    @what_was_selected = params[:what_was_selected]
    @allocation_tags_ids = params[:allocation_tags_ids].uniq
    authorize! :list, SupportMaterialFile, on: @allocation_tags_ids

    begin
      @allocation_tags = AllocationTag.find(@allocation_tags_ids)
    rescue
      render nothing: true, status: :unprocessable_entity
    end
  end

end
