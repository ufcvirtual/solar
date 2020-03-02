class PagesController < ApplicationController

  before_action :authenticate_user!, except: [:index, :privacy_policy, :apps, :tutorials, :faq, :tutorials_login]
  before_action :set_active_tab_to_home, only: :tutorials
  layout 'login', only: [:apps, :faq, :tutorials_login, :privacy_policy]

  def tutorials
    @verify_route_tutorial = false
  end

  def apps
  end

  def faq
  end

  def privacy_policy
  end

  def tutorials_login
    @verify_route_tutorial = true
  	render 'tutorials'
  end

  def general_shortcuts
    render layout: false
  end

end
