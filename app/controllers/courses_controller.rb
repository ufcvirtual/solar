class CoursesController < ApplicationController

  layout false

  def index
    authorize! :index, Course
    @type_id = params[:type_id].to_i

    if params[:combobox]
      if(@type_id == 3)
        @courses = Course.joins(offers: :curriculum_unit).where("curriculum_units.name = courses.name")
      else
        @courses = Course.all
      end
      render json: { html: render_to_string(partial: 'select_course.html', locals: { curriculum_units: @courses.uniq! }) }
    else # list
      if (not params[:course_id].blank?)
        @courses = Course.where(id: params[:course_id])
      else
        @courses = Course.all
      end
      render partial: 'courses/index'
    end
  end

  def new
    authorize! :create, Course
    @course = Course.new
    @type_id = params[:type_id].to_i

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  def edit
    authorize! :update, Course
    @course = Course.find(params[:id])
    @type_id = params[:type_id].to_i

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  def create
    authorize! :create, Course
    params[:course][:user_id] = current_user.id
    @course = Course.new(params[:course])
    @type_id = params[:type_id].to_i

    if @course.save
      if @type_id == 3
        uc = CurriculumUnit.new name: @course.name, code: @course.code, curriculum_unit_type_id: @type_id, resume: " - ", syllabus: " - ", objectives: " - "
        uc.user_id = @course.user_id
        uc.save
      end
      render json: {success: true, notice: t(:created, scope: [:courses, :success]), code_name: @course.code_name, id: @course.id}
    else
      render :new
    end
  end

  def update
    authorize! :update, Course
    @course = Course.find(params[:id])
    @type_id = params[:type_id].to_i
    curriculum_unit = CurriculumUnit.find_by_name(@course.name)

    if @course.update_attributes(params[:course])
      curriculum_unit.update_attributes name: @course.name, code: @course.code if @type_id == 3
      render json: {success: true, notice: t(:updated, scope: [:courses, :success]), code_name: @course.code_name, id: @course.id}
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, Course
    @course = Course.find(params[:id])
    curriculum_unit = CurriculumUnit.find_by_name(@course.name)    

    if @course.destroy
      curriculum_unit.try(:destroy) if params[:type_id].to_i == 3
      render json: {success: true, notice: t(:deleted, scope: [:courses, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:courses, :error])}, status: :unprocessable_entity
    end
  end
end
