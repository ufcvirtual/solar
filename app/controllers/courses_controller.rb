class CoursesController < ApplicationController

  def index
    # authorize! :index, Course

    al = current_user.allocations.where(status: Allocation_Activated)

    my_direct_courses = al.map(&:course).compact.uniq
    courses_by_period  = al.map(&:offer).compact.map(&:course).uniq
    courses_by_ucs     = al.map(&:curriculum_unit).compact.map(&:courses).flatten.uniq # apenas cursos ligados a disciplina pela oferta
    courses_by_groups  = al.map(&:group).compact.map(&:course).uniq
    @courses          = [my_direct_courses + courses_by_period + courses_by_ucs + courses_by_groups].flatten.compact.uniq

    # name or code
	if params.include?(:search)
		@courses  = @courses.select { |course| course.name.downcase.include?(params[:search].downcase) or course.code.downcase.include?(params[:search].downcase) }
		@courses.each do |course|
			course[:allocation_tag_id] = course.allocation_tag.id
		end
      
      optionAll = {:code => params[:search]+"...", :id => @courses.map(&:allocation_tag).map(&:id), :name =>"*"}
      @courses << optionAll
    end

    respond_to do |format| 
      format.html
      format.json { render json: @courses }
      format.xml { render xml: @courses }
    end
  end

end
