class LessonModulesController < ApplicationController

  layout false

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    # authorize
    @module = LessonModule.new
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    # teste para allocation_tag qualquer apenas para verificar validade dos dados
    @module = LessonModule.new(:name => params[:lesson_module][:name], :allocation_tag_id => @allocation_tags_ids.first.to_i) 

    begin
      # authorize
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
        format.html{ render :nothing => true, :status => 200 }
      end
    rescue CanCan::AccessDenied
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    rescue
      respond_to do |format|
        format.html{ render :new, :status => 200 }
      end
    end

  end

  def destroy
    @module = LessonModule.find(params[:id])
    @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      # authorize
      raise "error" unless @module.destroy # exclui as aulas dependentes e verifica se todas realmente podem ser excluídas (apenas se estiverem em teste)
      respond_to do |format|
        format.html{ render :nothing => true, :status => 200 }
      end
    rescue
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    end
  end

end
