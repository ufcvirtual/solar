class LessonModulesController < ApplicationController

  include SysLog::Actions

  layout false

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    authorize! :new, LessonModule, on: @allocation_tags_ids
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).map(&:code).uniq
    @lesson_module = LessonModule.new
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    # teste para allocation_tag qualquer apenas para verificar validade dos dados
    lesson_module = LessonModule.new(name: params[:lesson_module][:name])

    authorize! :create, LessonModule, on: @allocation_tags_ids
    raise "error" unless lesson_module.valid?
    
    LessonModule.transaction do
      @lesson_module = LessonModule.create!(name: params[:lesson_module][:name], is_default: false)
      @allocation_tags_ids.each do |id|
        AcademicAllocation.create!(allocation_tag_id: id, academic_tool_id: @lesson_module.id, academic_tool_type: 'LessonModule')
      end
    end

    respond_to do |format|
      format.html{ render nothing: true, status: 200 }
    end

  rescue CanCan::AccessDenied
    render nothing: true, status: 500
  rescue
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).map(&:code).uniq
    @allocation_tags_ids = @allocation_tags_ids.join(" ")
    render :new, status: 200
  end

  def edit
    authorize! :edit, LessonModule, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @lesson_module = LessonModule.find(params[:id])
    @groups_codes = @lesson_module.groups.map(&:code)
  end

  def update
    @allocation_tags_ids, @lesson_module = params[:allocation_tags_ids], LessonModule.find(params[:id])
    authorize! :update, LessonModule, on: @lesson_module.academic_allocations.pluck(:allocation_tag_id)

    @lesson_module.update_attributes!(name: params[:lesson_module][:name])

    render nothing: true, status: 200
  rescue CanCan::AccessDenied
    render nothing: true, status: 500
  rescue ActiveRecord::AssociationTypeMismatch
    render nothing: true, status: :unprocessable_entity
  rescue
    @groups = @lesson_module.groups
    render :new, status: 200
  end

  def destroy
    @lesson_module = LessonModule.find(params[:id])
    authorize! :destroy, LessonModule, on: @lesson_module.academic_allocations.pluck(:allocation_tag_id)

    if @lesson_module.destroy
      render json: {success: true, notice: t("lesson_modules.success.deleted")}, status: :ok
    else
      render json: {success: false, alert: @lesson_module.errors.full_messages}, status: :unprocessable_entity
    end
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

end
