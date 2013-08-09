class EnrollmentsController < ApplicationController

  def index
    authorize! :index, Enrollment
    @groups = []
    @types  = CurriculumUnitType.order(:name)
    @student_profile = Profile.student_profile
    @search_status  = params[:status]
    @status = [["Todos", "all"], ["Matriculados", "enroll"]]
    @curriculum_units = Enrollment.all_enrollments_by_user(current_user, @student_profile).map(&:offer).map(&:curriculum_unit)

    if current_user and (@student_profile != '')
      # recebe params[:offer] se foi pela pesquisa - MATRICULADOS e/ou ATIVOS
        @search_category = params[:type] if params.include?(:type)
        @search_curriculum_unit = params[:curriculum_unit] if params.include?(:curriculum_unit)

      if @search_status == 'enroll' # lista apenas matriculados
        @groups = Enrollment.enrollments_of_user(current_user, @student_profile, @search_category, @search_curriculum_unit)
      else
        @groups = Enrollment.all_enrollments_by_user(current_user, @student_profile, @search_category, @search_curriculum_unit)
      end
    end
  end

end
