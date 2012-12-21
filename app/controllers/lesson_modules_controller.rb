class LessonModulesController < ApplicationController

  layout false

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    # authorize
    @module = LessonModule.new
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    # faz um teste para allocation_tag qualquer apenas para verificar validade
    @module = LessonModule.new(:name => params[:lesson_module][:name], :allocation_tag_id => @allocation_tags_ids.first.to_i) 

    begin
      # authorize
      raise "error" unless @module.valid?

      @allocation_tags_ids.each do |id|
        LessonModule.create!(:name => params[:lesson_module][:name], :allocation_tag_id => id.to_i)
      end
      respond_to do |format|
        format.html{ render :url => {:controller => :lessons, :action => :list}, :status => 200 }
      end

    rescue CanCan::AccessDenied
      respond_to do |format|
        format.html{ render :url => {:controller => :lessons, :action => :list}, :status => 500 }
      end
    rescue Exception => error
      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end

  end

  def edit
    @allocation_tags_ids = params[:allocation_tags_ids]
    # authorize
    @module = LessonModule.find(params[:id])
  end

  def update
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @module = LessonModule.find(params[:id])

    begin
      # authorize
      @module.update_attributes!(:name => params[:lesson_module][:name])
      respond_to do |format|
        format.html{ render :url => {:controller => :lessons, :action => :list}, :status => 200 }
      end

    rescue CanCan::AccessDenied
      respond_to do |format|
        format.html{ render :url => {:controller => :lessons, :action => :list}, :status => 500 }
      end
    rescue Exception => error
      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end
  end

  def destroy
    # authorize
  end

end
