class BibliographyController < ApplicationController
  
  before_filter :prepare_for_group_selection, :only => [:list]
   
  def list
    allocation_tags_ids  = params[:allocation_tags_ids] || AllocationTag.find_related_ids(active_tab[:url][:allocation_tag_id])
    @bibliography 			 = Bibliography.all
    if params[:allocation_tags_ids]
    	@curriculum_units	   = CurriculumUnit.joins(:allocation_tag).where("allocation_tags.id IN (#{allocation_tags_ids.join(', ')})")
      @bibliography_filter = Bibliography.bibliography_filter(allocation_tags_ids)
      render :layout => false
    else
      @curriculum_units    = CurriculumUnit.find(active_tab[:url][:id])
      @bibliography_filter = Bibliography.bibliography_filter(allocation_tags_ids)
    end
  end

end