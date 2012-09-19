class GroupsController < ApplicationController

  # load_and_authorize_resource

  def index
    @groups = Group.find_all_by_curriculum_unit_id_and_user_id(params[:curriculum_unit_id], current_user.id) if params.include?(:curriculum_unit_id)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @groups }
      format.json  { render :json => @groups }
    end
  end

  def list
    @groups = Group.all # verificar quais grupos o usuario pode acessar
    @create_group = true

    respond_to do |format|
      format.html { render action: :index }
    end
  end

  def new
    @group = Group.new

    @offers = Offer.all
    @courses = Course.all
    @curriculum_units = CurriculumUnit.all
  end

  def edit
    @group = Group.find(params[:id])

    @offers = [@group.offer]
    @curriculum_units = [@offers.first.curriculum_unit]
    @courses = Course.all
  end

  def create
    # params[:group][:user_id] = current_user.id
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        format.html { redirect_to list_groups_url, notice: t(:successfully_created, :register => @group.code) }
      else
        format.html { render action: "new" }
      end
    end

  end

  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      redirect_to list_groups_url, notice: t(:successfully_updated, :register => @group.code)
    else
      redirect_to edit_group_url(@group), :alert => @group.errors
    end
  end

  def destroy
    @group = Group.find(params[:id])

    begin
      @group.destroy
      redirect_to list_groups_url, :notice => t(:successfully_deleted, :register => @group.code_semester)
    rescue
      redirect_to list_groups_url, :alert => t(:cant_delete, :register => @group.code_semester)
    end
  end

end
