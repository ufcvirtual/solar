class EnrollmentsController < ApplicationController

  def index
    authorize! :index, Enrollment
    student_profile = Profile.student_profile
    @groups = ["fdf"]
    @types  = CurriculumUnitType.order(:name)
    @status = [[t(:all, scope: [:enrollments]), "all"], [t(:enrolled, scope: [:enrollments]), "enroll"]]
    @search_status  = params[:status] || @status.first[1]
    @curriculum_units = Enrollment.enrollments_of_user(current_user, student_profile, "all").map(&:offer).map(&:curriculum_unit)

    if current_user and (@student_profile != '')
      # recebe params[:offer] se foi pela pesquisa - MATRICULADOS e/ou ATIVOS
      @search_category = params[:type] if params.include?(:type)
      @search_curriculum_unit = params[:curriculum_unit] if params.include?(:curriculum_unit)
      @groups = Enrollment.enrollments_of_user(current_user, student_profile, @search_status, @search_category, @search_curriculum_unit)
    end
  end

end
