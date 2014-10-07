class LessonModulesController < ApplicationController

  before_filter only: [:new, :create, :edit, :update] do |controller|
    authorize! crud_action, LessonModule, on: @allocation_tags_ids = params[:allocation_tags_ids].split(' ').flatten
  end

  include SysLog::Actions

  layout false

  def new
    groups_by_ats(@allocation_tags_ids)

    @lesson_module = LessonModule.new
    @lesson_module.academic_allocations.build @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
  end

  def create
    @lesson_module = LessonModule.new(params[:lesson_module])
    if @lesson_module.save
      render nothing: true
    else
      groups_by_ats(@allocation_tags_ids)
      @allocation_tags_ids = @allocation_tags_ids.join(' ')
      render :new
    end
  end

  def edit
    @lesson_module = LessonModule.find(params[:id])
    groups_by_lm(@lesson_module)
  end

  def update
    @lesson_module = LessonModule.find(params[:id])
    @lesson_module.update_attributes!(params[:lesson_module])

    render nothing: true
  rescue ActiveRecord::RecordInvalid
    groups_by_lm(@lesson_module)
    render :edit
  end

  def destroy
    @lesson_module = LessonModule.find(params[:id])
    authorize! :destroy, LessonModule, on: @lesson_module.academic_allocations.pluck(:allocation_tag_id)

    if @lesson_module.destroy
      render json: {success: true, notice: t("lesson_modules.success.deleted")}
    else
      render json: {success: false, alert: @lesson_module.errors.full_messages}, status: :unprocessable_entity
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def groups_by_ats(ats)
      @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: ats})
    end

    def groups_by_lm(lm)
      @groups = lm.groups
    end

end
