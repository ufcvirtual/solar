class DiscussionsController < ApplicationController

  def index
    authorize! :index, Discussion

    begin
      at_id = (active_tab[:url].include?('allocation_tag_id')) ? active_tab[:url]['allocation_tag_id'] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @discussions = Discussion.all_by_allocation_tags(AllocationTag.find_related_ids(at_id))
    rescue
      @discussions = []
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @discussions }
      format.json  { render :json => @discussions }
    end
  end

end
