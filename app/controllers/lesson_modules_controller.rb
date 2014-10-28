class LessonModulesController < ApplicationController

  include SysLog::Actions

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  before_filter only: [:new, :create, :edit, :update] do |controller|
    authorize! crud_action, LessonModule, on: @allocation_tags_ids = params[:allocation_tags_ids].split(' ').flatten
  end

  before_filter only: [:edit, :update] do |controller|
    get_groups_by_tool(@lesson_module = LessonModule.find(params[:id]))
  end

  layout false

  def new
    @lesson_module = LessonModule.new
  end

  def create
    @lesson_module = LessonModule.new lesson_module_params
    @lesson_module.allocation_tag_ids_associations = @allocation_tags_ids

    if @lesson_module.save
      render_lesson_module_success_json('created')
    else
      @allocation_tags_ids = @allocation_tags_ids.join(' ')
      render :new
    end
  end

  def edit
  end

  def update
    if @lesson_module.update_attributes(lesson_module_params)
      render_lesson_module_success_json('updated')
    else
      render :edit
    end
  end

  def destroy
    @lesson_module = LessonModule.find(params[:id])
    authorize! :destroy, LessonModule, on: @lesson_module.academic_allocations.pluck(:allocation_tag_id)

    if @lesson_module.destroy
      render_lesson_module_success_json('deleted')
    else
      render json: {success: false, alert: @lesson_module.errors.full_messages}, status: :unprocessable_entity
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def lesson_module_params
      params.require(:lesson_module).permit(:name)
    end

    def render_lesson_module_success_json(method)
      render json: {success: true, notice: t(method, scope: "lesson_modules.success")}
    end

end
