class DiscussionsController < ApplicationController

  def index
    authorize! :index, Discussion

    begin
      at_id = (active_tab[:url].include?('allocation_tag_id')) ? active_tab[:url]['allocation_tag_id'] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @discussions = AllocationTag.where(:id => AllocationTag.find_related_ids(at_id)).map { |at|
        at.discussions unless at.discussions.empty?
      }.compact.flatten
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
