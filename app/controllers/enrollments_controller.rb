class EnrollmentsController < ApplicationController

  layout false, except: :index

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

  def import_users
    @allocation_tags_ids = params[:allocation_tags_ids]
  end

  def batch_users
    raise t(:invalid_file, scope: [:users, :import]) if params[:file].nil?

    result = User.import(params[:file])
    users = result[:imported]
    log = result[:log]

    users.each do |u|
      params[:allocation_tags_ids].map(&:to_i).each do |at|
        allocation = Allocation.new user_id: u, profile_id: 1, allocation_tag_id: at, status: Allocation_Activated
        log[:error] << t(:allocation, scope: [:users, :import, :log], user: u, allocation_tag: at) unless allocation.save
      end
    end

    raise %{#{t(:success_with_warning, scope: [:users, :import], log: log[:error].join("<br/>"))}} unless log[:error].empty? or log[:error].nil?

    render json: {success: true, msg: t(:success, scope: [:users, :import])}
  rescue => error
    render json: {success: false, msg: "#{error}"}
  end

end
