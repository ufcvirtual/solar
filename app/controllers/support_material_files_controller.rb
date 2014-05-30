class SupportMaterialFilesController < ApplicationController

  include SysLog::Actions
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
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids]
    
    @support_material = SupportMaterialFile.new material_type: params[:material_type]
    @groups_codes     = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).map(&:code).uniq
  end

  def create
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    begin
      @support_material_file = SupportMaterialFile.new params[:support_material_file]
      SupportMaterialFile.transaction do
        @support_material_file.save!
        @support_material_file.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end

      render json: {success: true, notice: t(:created, scope: [:support_materials, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception => error
      if @support_material.is_link?
        @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).map(&:code).uniq
        @allocation_tags_ids = params[:allocation_tags_ids].join(" ")
        params[:success] = false
        render :new
      else
        render json: {success: false, alert: @support_material.errors.full_messages.join(" ")}, status: :unprocessable_entity
      end
    end
  end

  def edit
    authorize! :update, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @support_material = SupportMaterialFile.find(params[:id])
    @groups_codes = @support_material.groups.map(&:code)
  end

  def update
    @support_material_file = SupportMaterialFile.find(params[:id])
    authorize! :update, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      @support_material_file.update_attributes!(params[:support_material_file])
      render json: {success: true, notice: t(:updated, scope: [:support_materials, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @support_material_file.groups.map(&:code)
      params[:success] = false
      render :new
    end
  end

  def destroy
    authorize! :destroy, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      @support_material_file = SupportMaterialFile.where(id: params[:id].split(",").flatten)

      SupportMaterialFile.transaction do
        @support_material_file.destroy_all
      end
      render json: {success: true, notice: t(:deleted, scope: [:support_materials, :success])}
    rescue Exception => e
      render json: {success: false, msg: e.messages}, status: :unprocessable_entity
    end
  end

  def download
    allocation_tag_ids = params.include?(:allocation_tag_id) ? params[:allocation_tag_id].split(" ").flatten.map(&:to_i).uniq : [(file = SupportMaterialFile.find(params[:id])).academic_allocations.map(&:allocation_tag_id)]
    
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
      authorize! :download, SupportMaterialFile, {on: allocation_tag_ids, read: true}

      file ||= SupportMaterialFile.find(params[:id])
      download_file(support_material_files_path, file.attachment.path, file.attachment_file_name)
    end
  end

  def list
    @allocation_tags_ids = ( params.include?(:groups_by_offer_id) ? Offer.find(params[:groups_by_offer_id]).groups.map(&:allocation_tag).map(&:id) : params[:allocation_tags_ids] )
    authorize! :list, SupportMaterialFile, on: @allocation_tags_ids

    @support_materials = SupportMaterialFile.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).order("attachment_updated_at DESC").uniq
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render nothing: true, status: :unprocessable_entity
  end

end
