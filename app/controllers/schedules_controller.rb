class SchedulesController < ApplicationController

  def list

    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    curriculum_unit_id = params[:id]

    @curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
    @schedule = Schedule.all_by_group_id_and_user_id_and_curriculum_unit_id(group_id, user_id, curriculum_unit_id)

    #    # pegando dados da sessao e nao da url
    #   @groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    #   @offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    #    @bibliography = Bibliography.all
    #    @curriculum_unit = CurriculumUnit.all
    #    @curriculum_unit = CurriculumUnit.find(params[:id])

  end

end
