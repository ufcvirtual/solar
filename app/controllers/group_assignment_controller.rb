class GroupAssignmentController < ApplicationController
  #  before_filter :require_user
  before_filter :prepare_for_group_selection#, :only => [:list]

    # lista trabalhos em grupo
  def list
    #authorize! :list, Portfolio

    group_id = AllocationTag.find(active_tab[:url]['allocation_tag_id']).group_id
#puts "\n\n#{active_tab[:url]['allocation_tag_id']}\ngroup_id: #{group_id}\n\n\n"
    #@group_assignments = GroupAssignment.find

    # listando atividades individuais pelo grupo_id em que o usuario esta inserido
    #@individual_activities = Portfolio.individual_activities(group_id, current_user.id)
  end

end
