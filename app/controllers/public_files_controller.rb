class PublicFilesController < ApplicationController

  include FilesHelper

  before_filter :set_current_user, only: :destroy

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

    @public_file = PublicFile.new public_file_params
    @public_file.user_id = current_user.id
    @public_file.allocation_tag_id = allocation_tag_id
    @public_file.save!

    render partial: "file", locals: {file: @public_file, destroy: true}
  rescue => error
    render json: {success: false, alert: (@public_file.nil? ? t("public_files.error.new") : @public_file.errors.full_messages)}, status: :unprocessable_entity
  end

  def download
    authorize! :index, PublicFile, on: [allocation_tag_id = active_tab[:url][:allocation_tag_id]]

    if params[:zip].present?
      user = (params[:user_id].present? ? User.find(params[:user_id]) : current_user)
      path_zip = compress({ files: user.public_files.where(allocation_tag_id: allocation_tag_id), table_column_name: 'attachment_file_name', name_zip_file: t('public_files.index.title', name: user.name) })
      download_file(:back, path_zip)
    else
      file = PublicFile.find(params[:id])
      download_file(:back, file.attachment.path, file.attachment_file_name)
    end
  end

  def destroy
    PublicFile.find(params[:id]).destroy
    render json: {success: true, alert: t("public_files.success.removed")}
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def public_file_params
      params.require(:public_file).permit(:attachment)
    end

end
