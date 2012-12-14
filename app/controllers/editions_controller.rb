class EditionsController < ApplicationController

  authorize_resource :only => [:index]

  def index
  end


  def items
  	@allocation_tags_ids = params[:allocation_tags_ids]
  	render :partial => "items"
  end

end