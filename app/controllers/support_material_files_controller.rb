class SupportMaterialFilesController < ApplicationController

  include FilesHelper

  layout false, except: [:index]
  before_filter :prepare_for_group_selection, only: [:index]

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
      render :new
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
    rescue Exception => e
      render json: {success: false, msg: e.messages}, status: :unprocessable_entity
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
    authorize! :download, SupportMaterialFile, on: params[:allocation_tag_id].split(",").uniq

    if params.include?(:type)
      allocation_tag_ids = params[:allocation_tag_id].split(',').map(&:to_i)
      redirect_error = support_material_files_path

      all_files = case params[:type]
      when :all
        SupportMaterialFile.find_files(allocation_tag_ids)
      when :folder
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
    @allocation_tags_ids = params[:allocation_tags_ids].uniq
    authorize! :list, SupportMaterialFile, on: @allocation_tags_ids

    begin
      @allocation_tags = AllocationTag.find(@allocation_tags_ids)
    rescue
      render nothing: true, status: :unprocessable_entity
    end
  end

end
