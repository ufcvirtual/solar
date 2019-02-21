class ChangeLogsController < ApplicationController
  before_action :set_change_log, only: [:show, :update, :destroy]

  def index
    render json: Changelog.all.order(id: :desc).select { |m| m.academic_tool_type == params[:type] }
  end

  def show
    render json: @change_log
  end

  def create
  	puts change_log_params
    change_log = Changelog.new(change_log_params)

    if change_log.save
      render json: change_log 
    else
      render json: change_log.errors, status: :unprocessable_entity
    end
  end

  def update
    if @change_log.update(change_log_params)
      render json: @change_log
    else
      render json: @change_log.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @change_log.destroy
    render json: @change_log
  end

  private
    def set_change_log
      @change_log = Changelog.find(params[:id])
    end

    def change_log_params
      params.require(:change_log).permit(:academic_tool_type, :description, :deployment, :author)
    end
end
