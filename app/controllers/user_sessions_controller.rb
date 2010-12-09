class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:index, :new, :create]
  before_filter :require_user, :only => :destroy

  def index
	if ! @user_session
		@user_session = UserSession.new
	end
	render :action => :new
  end

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      redirect_back_or_default users_mysolar_url #('/')
    else
      flash[:notice] = 'Dados de login incorretos!'
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    redirect_back_or_default new_user_session_url
  end
end

