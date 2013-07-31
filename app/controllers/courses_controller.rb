class CoursesController < ApplicationController

  layout false

  def index
    if (not params[:course_id].blank?)
      @courses = Course.where(id: params[:course_id])
    else
      @courses = Course.all
    end

    render partial: 'courses/index'
  end

  def new
    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  def edit
    @course = Course.find(params[:id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  def create
    @course = Course.new(params[:course])
    # authorize! :create, Course

    if @course.save
      render json: {success: true, notice: t(:created, scope: [:courses, :success]), code_name: @course.code_name, id: @course.id}
    else
      render :new
    end
  end

  def update
    @course = Course.find(params[:id])

    if @course.update_attributes(params[:course])
      render json: {success: true, notice: t(:updated, scope: [:courses, :success]), code_name: @course.code_name, id: @course.id}
    else
      render :edit
    end
  end

  def destroy
    @course = Course.find(params[:id])
    #authorize! :destroy, Course

    if @course.destroy
      render json: {success: true, notice: t(:deleted, scope: [:courses, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:courses, :error])}, status: :unprocessable_entity
    end
  end


end
