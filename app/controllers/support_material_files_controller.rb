class SupportMaterialFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper

  layout false, except: [:index]
  before_filter :prepare_for_group_selection, only: [:index]

  def index
    authorize! :index, SupportMaterialFile, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    allocation_tag_ids = AllocationTag.find(@allocation_tag_id).related
    @list_files = SupportMaterialFile.find_files(allocation_tag_ids)

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
      @support_material = SupportMaterialFile.new params[:support_material_file]
      SupportMaterialFile.transaction do
        @support_material.save!
        @support_material.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end

      render json: {success: true, notice: t(:created, scope: [:support_materials, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception => error
      if @support_material.is_link?
        @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).map(&:code).uniq
        @allocation_tags_ids = params[:allocation_tags_ids].join(" ") rescue params[:allocation_tags_ids].split(" ")
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
    @support_material = SupportMaterialFile.find(params[:id])
    authorize! :update, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    begin
      @support_material.update_attributes!(params[:support_material_file])
      render json: {success: true, notice: t(:updated, scope: [:support_materials, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @support_material.groups.map(&:code)
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
    file = SupportMaterialFile.find(params[:id]) unless params[:id].blank?

    allocation_tag_ids = if not((current_at = active_tab[:url][:allocation_tag_id]).blank?) # dentro de uma UC
      ats = AllocationTag.find(current_at).related
      # se tenho acesso ao arquivo de dentro da UC que estou acessando
      file.nil? ? ats : file.academic_allocations.map(&:allocation_tag_id) & ats
    else # fora da UC
      file.academic_allocations.map(&:allocation_tag_id)
    end

    authorize! :download, SupportMaterialFile, on: allocation_tag_ids, read: true

    if not params[:type].blank? # folder ou all
      redirect_error = support_material_files_path

      folder = (params[:type] == :folder and not params[:folder].blank?) ? params[:folder] : nil
      path_zip = compress({ files: SupportMaterialFile.find_files(allocation_tag_ids, folder), table_column_name: 'attachment_file_name' })

      if path_zip
        download_file(redirect_error, path_zip)
      else
        redirect_to redirect_error, alert: t(:file_error_nonexistent_file)
      end
    else # baixando um arquivo individualmente
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
