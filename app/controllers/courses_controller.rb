class CoursesController < ApplicationController

  include SysLog::Actions

  layout false

  def index
    @type_id = params[:type_id].to_i
    except_courses = (@type_id == 3 ? '' : Course.all_associated_with_curriculum_unit_by_name.pluck(:id).join(','))

    if params[:combobox]
      @courses = (@type_id == 3 ? Course.all_associated_with_curriculum_unit_by_name : Course.where("id NOT IN (#{except_courses})"))
      render json: { html: render_to_string(partial: 'select_course.html', locals: { curriculum_units: @courses.distinct! }) }
    else # list
      authorize! :index, Course
      @courses = if params[:course_id].present?
        Course.where(id: params[:course_id]).where("courses.id NOT IN (#{except_courses})").paginate(page: params[:page])
      else
        allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], 'courses')
        Course.joins(:allocation_tag).where(allocation_tags: { id: allocation_tags_ids }).where("courses.id NOT IN (#{except_courses})").paginate(page: params[:page])
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
  end

  def edit
    @course = Course.find(params[:id])
    authorize! :update, @course
  end

  def create
    authorize! :create, Course

    @course = Course.new(course_params)
    @course.user_id = current_user.id

    if @course.save
      render_course_success_json('created')
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
      render_course_success_json('updated')
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
      render_course_success_json('deleted')
    else
      render json: {success: false, alert: (@course.errors.full_messages.any? ? @course.errors.full_messages.join(', ') : t('courses.error.deleted'))}, status: :unprocessable_entity
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def course_params
      params.require(:course).permit(:name, :code, :passing_grade, :min_grade_to_final_exam, :min_final_exam_grade, :final_exam_passing_grade, :min_hours, :has_exam_header, :header_exam)
    end

    def render_course_success_json(method)
      render json: {success: true, notice: t(method, scope: 'courses.success'), code_name: @course.code_name, id: @course.id}
    end

end
