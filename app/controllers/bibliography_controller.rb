class BibliographyController < ApplicationController
  
  before_filter :prepare_for_group_selection, :only => [:list]
   
  def list
    allocations = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])

    @bibliography = Bibliography.all
    @curriculum_unit = CurriculumUnit.find(active_tab[:url]['id'])
    @bibliography_filter= Bibliography.bibliography_filter(allocations)
  end

end
