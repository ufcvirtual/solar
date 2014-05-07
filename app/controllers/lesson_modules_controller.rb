class LessonModulesController < ApplicationController

  include SysLog::Actions

  layout false

  def new
    authorize! :new, LessonModule, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).uniq
    @module = LessonModule.new
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    # teste para allocation_tag qualquer apenas para verificar validade dos dados
    lesson_module = LessonModule.new(:name => params[:lesson_module][:name])

    begin
      authorize! :create, LessonModule, :on => @allocation_tags_ids
      raise "error" unless lesson_module.valid?
      
      LessonModule.transaction do
        @lesson_module = LessonModule.create!(:name => params[:lesson_module][:name], is_default: false)
        @allocation_tags_ids.each do |id|
          AcademicAllocation.create!(allocation_tag_id: id, academic_tool_id: @lesson_module.id, academic_tool_type: 'LessonModule')
        end
      end

      respond_to do |format|
        format.html{ render :nothing => true, :status => 200 }
      end

    rescue CanCan::AccessDenied
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    rescue => error
      @groups = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).uniq

      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end

  end

  def edit
    authorize! :edit, LessonModule, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @module = LessonModule.find(params[:id])
    @groups = @module.groups
  end

  def update
    @lesson_module = LessonModule.find(params[:id])
    allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    begin
      authorize! :update, LessonModule, :on => allocation_tags_ids
      @lesson_module.update_attributes!(:name => params[:lesson_module][:name])

      respond_to do |format|
        format.html{ render :nothing => true, :status => 200 }
      end
    rescue CanCan::AccessDenied
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    rescue ActiveRecord::AssociationTypeMismatch
      render nothing: true, status: :unprocessable_entity
    rescue
      @groups = @lesson_module.groups
      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end

  end

  def destroy
    authorize! :destroy, LessonModule, :on => params[:allocation_tags_ids]
    @lesson_module = LessonModule.find(params[:id])

    if @lesson_module.destroy
      render json: {success: true}, status: :ok
    else
      render json: {success: false, alert: @lesson_module.errors.full_messages}, status: :unprocessable_entity
    end
  end

end
