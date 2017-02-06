class PagesController < ApplicationController

  before_filter :authenticate_user!, except: [:index, :team, :apps, :privacy, :tutorials]
  before_filter :set_active_tab_to_home, only: :tutorials
  layout 'login', only: [:apps, :privacy]

  def tutorials
  end

  def apps
  end

  def privacy
  end

end
