class BibliographiesController < ApplicationController

  include SysLog::Actions
  include FilesHelper

  layout false, except: :index # define todos os layouts do controller como falso
  before_filter :prepare_for_group_selection, only: [:index]

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  before_filter only: [:edit, :update] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@bibliography = Bibliography.find(params[:id]))
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Bibliography, on: @allocation_tags_ids

    @bibliographies = Bibliography.joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: @allocation_tags_ids.split(' ').flatten }).uniq
  end

  # GET /bibliographies
  def index
    authorize! :index, Bibliography, on: [at = active_tab[:url][:allocation_tag_id]]

    @bibliographies = Bibliography.all_by_allocation_tags(at) # tem que listar bibliografias relacionadas para cima
  end

  # GET /bibliographies/new
  def new
    authorize! :create, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @bibliography = Bibliography.new type_bibliography: params[:type_bibliography]
    @bibliography.authors.build
  end

  # GET /bibliographies/1/edit
  def edit
    raise 'cant_edit_file' if @bibliography.is_file?
    authorize! :update, Bibliography, on: @allocation_tags_ids
  end

  # POST /bibliographies
  def create
    authorize! :create, Bibliography, on: @allocation_tags_ids = params[:allocation_tags_ids].split(' ').flatten

    (params[:bibliography][:type_bibliography].to_i == Bibliography::TYPE_FILE) ? create_many : create_one
    
    render json: { success: true, notice: t(:created, scope: [:bibliographies, :success]) }
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue
    @allocation_tags_ids = @allocation_tags_ids.join(' ')
    params[:success] = false
    if @bibliography.nil? || @bibliography.is_file?
      render json: { success: false, alert: t('bibliographies.error.file') }
    else
      render :new
    end
  end

  # PUT /bibliographies/1
  def update
    raise 'cant_edit_file' if @bibliography.is_file?
    authorize! :update, Bibliography, on: @bibliography.academic_allocations.pluck(:allocation_tag_id)
    @bibliography.update_attributes!(bibliography_params)
    render json: { success: true, notice: t(:updated, scope: [:bibliographies, :success]) }
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue
    params[:success] = false
    render :edit
  end

  # DELETE /bibliographies/1
  def destroy
    @bibliographies = Bibliography.where(id: params[:id].split(','))
    authorize! :destroy, Bibliography, on: @bibliographies.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    @bibliographies.destroy_all

    render json: { success: true, notice: t(:deleted, scope: [:bibliographies, :success]) }
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue
    render json: { success: false, alert: t(:deleted, scope: [:bibliographies, :error]) }, status: :unprocessable_entity
  end

  def download
    if params.include?(:id)
      bibliographies_to_download = Bibliography.find(params[:id])
      allocation_tags_ids        = bibliographies_to_download.allocation_tags.pluck(:id)
    else
      allocation_tags_ids        = (active_tab[:url][:allocation_tag_id].blank? ? params[:allocation_tags_ids] : active_tab[:url][:allocation_tag_id])
      bibliographies_to_download = Bibliography.joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }, type_bibliography: Bibliography::TYPE_FILE).uniq
    end

    authorize! :download, Bibliography, on: allocation_tags_ids, read: true
    redirect_error = bibliographies_path

    if bibliographies_to_download.respond_to?(:length)
      path_zip = compress({ files: bibliographies_to_download, table_column_name: 'attachment_file_name', name_zip_file: t('bibliographies.zip', info: AllocationTag.find(allocation_tags_ids).first.offers.first.info) })
      if path_zip
        download_file(redirect_error, path_zip)
      else
        redirect_to redirect_error, alert: t(:file_error_nonexistent_file)
      end
    else
      download_file(redirect_error, bibliographies_to_download.attachment.path, bibliographies_to_download.attachment_file_name)
    end
  end

  private

    def bibliography_params
      params.require(:bibliography).permit(:type_bibliography, :title, :subtitle, :address, :publisher, :pages,
        :count_pages, :volume, :edition, :publication_year, :periodicity, :issn, :isbn, :periodicity_year_start,
        :periodicity_year_end, :article_periodicity_title, :fascicle, :publication_month, :additional_information,
        :url, :accessed_in, :attachment, authors_attributes: [:id, :name, :_destroy])
    end

    def create_one(params=bibliography_params)
      @bibliography = Bibliography.new(params)

      Bibliography.transaction do
        @bibliography.allocation_tag_ids_associations = @allocation_tags_ids
        @bibliography.save!
        # @bibliography.academic_allocations.create @allocation_tags_ids.map { |at| { allocation_tag_id: at } }
      end
    end

    def create_many
      Bibliography.transaction do
        params[:files].each do |file|
          create_one(bibliography_params.merge!(attachment: file))
        end
      end
    end

end
