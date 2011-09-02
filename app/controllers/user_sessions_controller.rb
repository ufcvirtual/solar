class UserSessionsController < ApplicationController

  layout 'login'

  before_filter :require_no_user, :only => [:index, :new, :create]
  before_filter :require_user, :only => :destroy
  before_filter :bread_crumb, :only => :create

  def index
    if !@user_session
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
      # grava log de acesso
      Log.create(:log_type => Log::TYPE[:login], :user_id => @user_session.user.id)

      # gera aba para Home
      redirect_to :action => "add_tab", :controller => "application", :name => 'Home', :type => Tab_Type_Home
    else
      flash[:notice] = t(:login_data_invalid)
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    #limpa sessao
    reset_session
    redirect_back_or_default new_user_session_url(:locale => I18n.locale)
  end

  BreadCrumb_First_Level = 0

  def bread_crumb
    session[:breadcrumb] = Array.new
    session[:breadcrumb][BreadCrumb_First_Level] = {
      :name => "Home",
      :params => {
        :controller => :users,
        :action => :mysolar
      }
    }
  end

end
