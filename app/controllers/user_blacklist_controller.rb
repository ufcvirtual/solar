class UserBlacklistController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  # GET /user_blacklist
  # GET /user_blacklist.json
  def index
    authorize! :index, UserBlacklist

    @user_blacklist = UserBlacklist.all

    render layout: false if params[:layout].present? and params[:layout] == 'false'
  end

  # GET /user_blacklist/new
  # GET /user_blacklist/new.json
  def new
    authorize! :create, UserBlacklist

    @user_blacklist = UserBlacklist.new
  end

  # POST /user_blacklist
  # POST /user_blacklist.json
  def create
    authorize! :create, UserBlacklist

    @user_blacklist = UserBlacklist.new(params[:user_blacklist])
    @user_blacklist.user = current_user

    begin
      @user_blacklist.save!

      render json: {success: true, notice: t('user_blacklist.success.created', cpf: @user_blacklist.cpf)}
    rescue
      render :new
    end
  end

  def add_user
    authorize! :create, UserBlacklist

    user = User.find(params[:user_id])

    begin
      user_bl = user.add_to_blacklist(current_user.id)

      raise if user_bl.errors.any?

      render json: {success: true, notice: t('user_blacklist.success.created', cpf: user.cpf)}
    rescue
      alert = user_bl.errors.any? ? user_bl.errors.full_messages : t('user_blacklist.error.created')

      render json: {success: false, alert: alert}, status: :unprocessable_entity
    end
  end

  def search
    authorize! :index, UserBlacklist

    @user_blacklist = params[:search].present? ? UserBlacklist.search(params[:search]) : UserBlacklist.all

    render partial: 'blacklist'
  end

  # DELETE /user_blacklist/1
  # DELETE /user_blacklist/1.json
  def destroy
    authorize! :create, UserBlacklist

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
