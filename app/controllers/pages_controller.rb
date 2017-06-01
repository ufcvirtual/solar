class PagesController < ApplicationController

  before_filter :authenticate_user!, except: [:index, :team, :apps, :tutorials, :faq, :tutorials_login]
  before_filter :set_active_tab_to_home, only: :tutorials
  layout 'login', only: [:apps, :team, :faq, :tutorials_login]

  def tutorials
  end

  def apps
  end

  def team
  	@sectors = YAML::load(File.open('public/members.yml'))
  end

  def faq
  end

  def tutorials_login
  	render 'tutorials'
  end

end
