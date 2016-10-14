class PagesController < ApplicationController

  before_filter :authenticate_user!, except: [:index, :team]
  before_filter :set_active_tab_to_home, only: :tutorials

  def tutorials
  end

end
