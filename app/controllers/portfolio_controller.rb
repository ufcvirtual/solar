class PortfolioController < ApplicationController

#  load_and_authorize_resource

  def list
    @curriculum_unit = CurriculumUnit.find(params[:id])
  end

end
