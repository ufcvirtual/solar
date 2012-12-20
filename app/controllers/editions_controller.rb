class EditionsController < ApplicationController

  authorize_resource :only => [:index]

  def index
  end

  def items
  	@allocation_tags_ids = params[:allocation_tags_ids] || []
    @selected_course     = @allocation_tags_ids.collect{|id| true if AllocationTag.find(id).course}.include?(true)
    @selected_offer      = @allocation_tags_ids.collect{|id| true if AllocationTag.find(id).offer}.include?(true)
    @selected_group      = @allocation_tags_ids.collect{|id| true if AllocationTag.find(id).group}.include?(true)
  	render :partial => "items"
  end

end