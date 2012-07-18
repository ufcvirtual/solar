class ScoresTeacherController < ApplicationController

  before_filter :prepare_for_pagination, :only => [:list]
  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, ScoresTeacher

    curriculum_unit_id = active_tab[:url]['id']
    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    @group = Group.joins(:allocation_tag).where("allocation_tags.id = ?", allocation_tag_id).first
    @students, @activities, @students_count = [], [], 0

    unless @group.nil?
      @students_count = ScoresTeacher.number_of_students_by_group_id(@group.id)
      @activities = @group.assignments + @group.offer.assignments

      curriculum_unit_id = params[:id]
      @students = ScoresTeacher.list_students_by_curriculum_unit_id_and_group_id(curriculum_unit_id, @group.id, @current_page)
    end

  end

end
