class PublicFilesController < ApplicationController

  include FilesHelper

  before_filter :set_current_user, only: [:destroy]

  layout false, except: :index

  def index
    authorize! :index, PublicFile, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    @user = User.find(params[:user_id])
    @public_files = @user.public_files.where allocation_tag_id: allocation_tag_id
  end

  def new
    @public_file = PublicFile.new
  end

  def create
    authorize! :create, PublicFile, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    public_file = PublicFile.create!(params[:public_file].merge({user_id: current_user.id, allocation_tag_id: allocation_tag_id}))
    render partial: "file", locals: {file: public_file, destroy: true}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t("public_files.error.new")}, status: :unprocessable_entity
  end

  def download
    authorize! :index, PublicFile, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    if params[:zip].present?
      user     = (params[:user_id].present? ? User.find(params[:user_id]) : current_user)
      path_zip = compress({ files: user.public_files.where(allocation_tag_id: allocation_tag_id), table_column_name: 'attachment_file_name', name_zip_file: "Arquivos Públicos - #{user.name}" })
      download_file(:back, path_zip)
    else
      file = PublicFile.find(params[:id])
      download_file(:back, file.attachment.path, file.attachment_file_name)
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render js: "flash_message('#{t(:file_error_nonexistent_file)}', 'alert');"
  end

  def destroy
    PublicFile.find(params[:id]).destroy
    render json: {success: true, alert: t("public_files.success.removed")}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: t("public_files.error.remove")}, status: :unprocessable_entity
  end

end
