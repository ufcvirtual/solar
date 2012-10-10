class CoursesController < ApplicationController

  def index
    # authorize! :index, Course

    # recuperando todas as unidades curriculares que o usuario interage
    al        = current_user.allocations
    courses_d = al.joins(:course).where(courses: {name: params[:name]}).compact # cursos diretamente
    courses_a = al.map(&:offer).compact.map(&:course) + al.map(&:group).compact.map(&:course).compact # atraves das associacoes
    @courses  = [courses_d + courses_a].flatten.compact.uniq

    ## aplicando filtro
    if params.include?(:search)
      @courses  = @courses.select {|course| course.name.downcase.include?(params[:search].downcase) or course.code.downcase.include?(params[:search].downcase) }
    end

    respond_to do |format| 
      format.html
      format.xml { render xml: @courses }
      format.json { render json: @courses }
    end
  end

end
