class EditionsController < ApplicationController
  

  def index
  	authorize! :index, Edition

  	# temporário com a finalidade de testes. quando for definido o acesso à página, utilizar dados obtidos pelo filtro
  	@curriculum_unit_id, @course_id, @offer_id, @group_id = 3, 2, 3, "all"

  	# ids das allocations_tags de acordo com os dados passados
  	@allocation_tags_ids = [AllocationTag.by_course_and_curriculum_unit_and_offer_and_group(@course_id, @curriculum_unit_id, @offer_id, @group_id)].flatten

  	render :layout => false if params[:layout]
  end

end