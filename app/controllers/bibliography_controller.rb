class BibliographyController < ApplicationController
  
  before_filter :prepare_for_group_selection, :only => [:list]
   
  def list
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    allocations = AllocationTag.find_related_ids(active_tab['allocation_tag_id'])

    @bibliography = Bibliography.all
    @curriculum_unit = CurriculumUnit.find(active_tab['id'])
    @bibliography_filter= Bibliography.bibliography_filter(allocations)
  end

end
