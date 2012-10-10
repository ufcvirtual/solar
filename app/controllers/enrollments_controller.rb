class EnrollmentsController < ApplicationController

  def index
    authorize! :index, Enrollment

    @types = CurriculumUnitType.order(:description)
    @student_profile = student_profile
    @offers = []

    if current_user and (@student_profile != '')
      # lista apenas matriculados
      if params[:category_query] == 'enroll'
        @offers = Allocation.enrollments_of_user(current_user, @student_profile)
      else
        # recebe params[:offer] se foi pela pesquisa - MATRICULADOS e/ou ATIVOS
        if params.include?(:offer)
          @search_category = params[:offer][:category] if params[:offer].include?(:category)
          @search_text = params[:offer][:search] if params[:offer].include?(:search)
        end
        @offers = Allocation.all_enrollments_by_user(current_user, @student_profile, @search_category, @search_text)
      end

      @user = current_user
    end
  end

end
