class ScoresTeacherController < ApplicationController

  before_filter :prepare_for_pagination, :only => [:list]
  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, ScoresTeacher

    curriculum_unit_id = active_tab[:url]['id']
    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    allocations = AllocationTag.find_related_ids(allocation_tag_id)

    groups = AllocationTag.find_all_groups(allocations.join(','))
    @group, group_id = groups.first.code, groups.first.id
    @students, @activities, @cnt_students = [], [], 0

    unless group_id.nil?
      @cnt_students = ScoresTeacher.number_of_students_by_group_id(group_id)
      @activities = Assignment.all_by_group_id(group_id)

      curriculum_unit_id = params[:id]
      @students = ScoresTeacher.list_students_by_curriculum_unit_id_and_group_id(curriculum_unit_id, group_id, @current_page)
    end
  end

end
