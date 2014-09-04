class UserBlacklistController < ApplicationController

  include SysLog::Actions

  layout false, except: :index

  # GET /user_blacklist
  # GET /user_blacklist.json
  def index
    authorize! :index, UserBlacklist

    @user_blacklist = UserBlacklist.paginate(page: params[:page])

    respond_to do |format|
      format.html {
        render layout: false if params[:layout].present? and params[:layout] == 'false'
      }
      format.js
    end
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

    begin
      user = User.find(params[:user_id])
      @user_blacklist = user.add_to_blacklist(current_user.id) # variavel para gerar log
      @can_change = true

      raise if @user_blacklist.errors.any?

      render json: {success: true, notice: t('user_blacklist.success.created', cpf: user.cpf), user: render_to_string(partial: 'administrations/user', locals: {user: user})}
    rescue
      alert = @user_blacklist.errors.any? ? @user_blacklist.errors.full_messages : t('user_blacklist.error.created')

      render json: {success: false, alert: alert}, status: :unprocessable_entity
    end
  end

  def search
    authorize! :index, UserBlacklist

    @user_blacklist = params[:search].present? ? UserBlacklist.search(params[:search]).paginate(page: params[:page]) : UserBlacklist.paginate(page: params[:page])

    render partial: 'blacklist'
  end

  # DELETE /user_blacklist/1
  # DELETE /user_blacklist/1.json
  def destroy
    authorize! :create, UserBlacklist

    @can_change = true
    @user_blacklist = if params[:type].present? and params[:type] == 'remove'
      UserBlacklist.find_by_cpf(params[:user_cpf])
    else
      UserBlacklist.find(params[:id])
    end

    begin
      user = User.find_by_cpf(@user_blacklist.cpf)
      @user_blacklist.destroy

      render json: {success: true, notice: t('user_blacklist.success.deleted', cpf: @user_blacklist.cpf), user: render_to_string(partial: 'administrations/user', locals: {user: user})}
    rescue
      render json: {success: false, alert: t('user_blacklist.error.deleted')}, status: :unprocessable_entity
    end
  end
end
