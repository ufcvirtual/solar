class LessonModulesController < ApplicationController

  layout false

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    authorize! :new, LessonModule, :on => @allocation_tags_ids
    @module              = LessonModule.new
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    # teste para allocation_tag qualquer apenas para verificar validade dos dados
    @module = LessonModule.new(:name => params[:lesson_module][:name], :allocation_tag_id => @allocation_tags_ids.first.to_i) 

    begin
      authorize! :create, LessonModule, :on => @allocation_tags_ids
      raise "error" unless @module.valid?

      @allocation_tags_ids.each do |id|
        LessonModule.create!(:name => params[:lesson_module][:name], :allocation_tag_id => id.to_i)
      end

      respond_to do |format|
        format.html{ render :nothing => true, :status => 200 }
      end

    rescue CanCan::AccessDenied
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    rescue Exception => error
      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end

  end

  def edit
    @allocation_tags_ids = params[:allocation_tags_ids]
    @module              = LessonModule.find(params[:id])
    authorize! :edit, @module
  end

  def update
    @module = LessonModule.find(params[:id])

    begin
      authorize! :update, @module
      @module.update_attributes!(:name => params[:lesson_module][:name])

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
      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end

  end

  def destroy
    authorize! :destroy, @module = LessonModule.find(params[:id])

    if @module.destroy
      render json: {success: true}, status: :ok
    else
      render json: {success: false, alert: @module.errors.full_messages}, status: :unprocessable_entity
    end
  end

end
