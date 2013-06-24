class EnrollmentsController < ApplicationController

  def index
    authorize! :index, Enrollment

    @groups = []
    @types  = CurriculumUnitType.order(:description)
    @student_profile = Profile.student_profile
    @category_query  = params[:category_query]

    if current_user and (@student_profile != '')
      # recebe params[:offer] se foi pela pesquisa - MATRICULADOS e/ou ATIVOS
      if params.include?(:offer)
        @search_category = params[:offer][:category] if params[:offer].include?(:category)
        @search_text     = params[:offer][:search] if params[:offer].include?(:search)
      end

      if @category_query == 'enroll' # lista apenas matriculados
        @groups = Enrollment.enrollments_of_user(current_user, @student_profile, @search_category, @search_text)
      else
        @groups = Enrollment.all_enrollments_by_user(current_user, @student_profile, @search_category, @search_text)
      end
    end
  end

end
