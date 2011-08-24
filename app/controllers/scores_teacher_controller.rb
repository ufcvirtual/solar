class ScoresTeacherController < ApplicationController

  before_filter :require_user

  before_filter :prepare_for_pagination, :only => [:list]

  # lista de alunos paginados
  def list

    authorize! :list, ScoresTeacher

    curriculum_unit_id = params[:id]
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # lista de estudantes paginada
    @cnt_students = ScoresTeacher.number_of_students_by_group_id(group_id)
    @activities = Assignment.all_by_group_id(group_id)
    @students = ScoresTeacher.list_students_by_curriculum_unit_id_and_group_id(curriculum_unit_id, group_id, @current_page)
    @group = Group.find(group_id).code || nil

  end

end
