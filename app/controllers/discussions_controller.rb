class DiscussionsController < ApplicationController

  load_and_authorize_resource :only => [:index]

  def index
    @discussions = []
    ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])

    allocation_tags = AllocationTag.where(:id => ids)
    allocation_tags.each do |at|
      @discussions += at.discussions
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @discussions }
      format.json  { render :json => @discussions }
    end
  end

end