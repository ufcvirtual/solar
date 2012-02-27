class UserSessionsController < ApplicationController

#  layout 'login'

  #before_filter :require_no_user, :only => [:index, :new, :create]
  #before_filter :require_user, :only => :destroy
  before_filter :bread_crumb, :only => :create

  def index
    if !@user_session
      @user_session = UserSession.new
    end
    render :action => :new
  end

  def new
    user_session[:tabs] = {:opened => {'Home' => {'context' => Context_General}}, :active => 'Home'}

    # antes de criar uma nova sessao limpa qualquer outra existente
#    destroy_session
#    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      # grava log de acesso
      Log.create(:log_type => Log::TYPE[:login], :user_id => @user_session.user.id)

      # gera aba para Home
      redirect_to :action => "add_tab", :controller => "application", :name => 'Home', :context => Context_General
    else
      flash[:notice] = t(:login_data_invalid)
      render :action => :new
    end
  end

  def destroy

    raise "here destroy session"

#    destroy_sesession
#
#    redirect_to root_url

#    redirect_back_or_default new_user_session_url(:locale => I18n.locale)
  end

  # Criacao da migalha de pao
  def bread_crumb
    session[:breadcrumb] = Array.new
    session[:breadcrumb][BreadCrumb_First_Level] = {
      :name => 'home',
      :url => {
        :controller => :application,
        :action => :activate_tab,
        :name => 'Home',
        :context => Context_General
      }
    }
  end

  private

  def destroy_session
#    current_user_session.destroy unless current_user_session.nil?
#    #limpa sessao
#    reset_session
  end

end
