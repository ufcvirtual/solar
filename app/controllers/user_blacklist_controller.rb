class UserBlacklistController < ApplicationController

  layout false, except: :index

  # GET /user_blacklist
  # GET /user_blacklist.json
  def index
    @user_blacklist = UserBlacklist.all

    render layout: false if params[:layout].present? and params[:layout] == 'false'
  end

  # GET /user_blacklist/new
  # GET /user_blacklist/new.json
  def new
    @user_blacklist = UserBlacklist.new
  end

  def add_user
    user = User.find(params[:user_id])

    if user.add_to_blacklist
      render json: {success: true, notice: t('user_blacklist.success.created', cpf: user.cpf)}
    else
      render json: {success: false, alert: t('user_blacklist.error.craeted')}, status: :unprocessable_entity
    end
  end

  # POST /user_blacklist
  # POST /user_blacklist.json
  def create
    @user_blacklist = UserBlacklist.new(params[:user_blacklist])

    begin
      @user_blacklist.save!

      render json: {success: true, notice: t('user_blacklist.success.created', cpf: @user_blacklist.cpf)}
    rescue
      render :new
    end
  end

  # DELETE /user_blacklist/1
  # DELETE /user_blacklist/1.json
  def destroy
    user_blacklist = if params[:type].present? and params[:type] == 'remove'
      UserBlacklist.find_by_cpf(params[:user_cpf])
    else
      UserBlacklist.find(params[:id])
    end

    begin
      user_blacklist.destroy

      render json: {success: true, notice: t('user_blacklist.success.deleted', cpf: user_blacklist.cpf)}
    rescue
      render json: {success: false, alert: t('user_blacklist.error.deleted')}, status: :unprocessable_entity
    end
  end
end
