class GroupAssignmentController < ApplicationController

  before_filter :prepare_for_group_selection#, :only => [:list]

  # lista trabalhos em grupo
  def list
    #authorize! :list, Portfolio

    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
    
    @group_assignments = GroupAssignment.all_by_group_id(group_id)
  end

end
