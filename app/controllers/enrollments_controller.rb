class EnrollmentsController < ApplicationController

  def index
    authorize! :index, Enrollment

    @types  = CurriculumUnitType.order(:description)
    @offers = []
    @student_profile = Profile.student_profile
    @category_query  = params[:category_query]

    if current_user and (@student_profile != '')

      # recebe params[:offer] se foi pela pesquisa - MATRICULADOS e/ou ATIVOS
      if params.include?(:offer)
        @search_category = params[:offer][:category] if params[:offer].include?(:category)
        @search_text     = params[:offer][:search] if params[:offer].include?(:search)
      end

      # lista apenas matriculados
      if @category_query == 'enroll'
        @offers = Enrollment.enrollments_of_user(current_user, @student_profile, @search_category, @search_text)
      else
        @offers = Enrollment.all_enrollments_by_user(current_user, @student_profile, @search_category, @search_text)
      end

      @user = current_user
    end
  end

end
