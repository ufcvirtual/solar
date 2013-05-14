class PagesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :team]
  
  def index
    render :layout => 'external_page'
  end

end
