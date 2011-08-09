class SchedulesController < ApplicationController
   
  def list

    @curriculum_unit = CurriculumUnit.find(params[:id])

    @schedule = Schedule.all_by_group_id_and_user_id(1, 1)
    
#    # pegando dados da sessao e nao da url
#   @groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
#   @offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

#    @bibliography = Bibliography.all
#    @curriculum_unit = CurriculumUnit.all
#    @curriculum_unit = CurriculumUnit.find(params[:id])

  end

end
