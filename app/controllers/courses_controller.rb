class CoursesController < ApplicationController

  layout false

  def index
    @type_id = params[:type_id].to_i

    if params[:combobox]
      @courses = (@type_id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.all)
      render json: { html: render_to_string(partial: 'select_course', locals: { curriculum_units: @courses.uniq! }) }
    else # list
      authorize! :index, Course
      @courses = if params[:course_id].present?
        Course.where(id: params[:course_id]).paginate(page: params[:page])
      else
        allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "courses")
        Course.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).paginate(page: params[:page])
      end

      respond_to do |format|
        format.html {render partial: 'courses/index'}
        format.js
      end
    end
  end

  def new
    authorize! :create, Course
    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  def edit
    @course = Course.find(params[:id])
    authorize! :update, @course

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  def create
    authorize! :create, Course

    @course = Course.new(course_params)
    @course.user_id = current_user.id

    if @course.save
      render json: {success: true, notice: t(:created, scope: [:courses, :success]), code_name: @course.code_name, id: @course.id}
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def update
    @course = Course.find(params[:id])
    authorize! :update, @course

    if @course.update_attributes(course_params)
      render json: {success: true, notice: t(:updated, scope: [:courses, :success]), code_name: @course.code_name, id: @course.id}
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @course = Course.find(params[:id])
    authorize! :destroy, @course

    if @course.destroy
      render json: {success: true, notice: t(:deleted, scope: [:courses, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:courses, :error])}, status: :unprocessable_entity
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: I18n.t("courses.error.deleted")}, status: :unprocessable_entity
  end

  private

    def course_params
      params.require(:course).permit(:name, :code)
    end

end
