class CoursesController < ApplicationController

  def index
    # authorize! :index, Course

    # recuperando todas as unidades curriculares que o usuario interage
    al                = current_user.allocations
    my_direct_courses = al.map(&:course).compact.uniq
    course_by_period  = al.map(&:offer).compact.map(&:course).uniq
    course_by_ucs     = al.map(&:curriculum_unit).compact.map(&:courses).flatten.uniq # apenas cursos ligados a disciplina pela oferta
    course_by_groups  = al.map(&:group).compact.map(&:course).uniq
    @courses          = [my_direct_courses + course_by_period + course_by_ucs + course_by_groups].flatten.compact.uniq

    # name or code
    if params.include?(:search)
      @courses  = @courses.select { |course| course.name.downcase.include?(params[:search].downcase) or course.code.downcase.include?(params[:search].downcase) }
    end

    respond_to do |format| 
      format.html
      format.json { render json: @courses }
      format.xml { render xml: @courses }
    end
  end

end
