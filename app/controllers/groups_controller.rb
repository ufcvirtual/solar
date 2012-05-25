class GroupsController < ApplicationController

  # load_and_authorize_resource

  def index
    @groups = CurriculumUnit.find_user_groups_by_curriculum_unit(params[:curriculum_unit_id], current_user.id) if params.include?(:curriculum_unit_id)

    respond_to do |format|
      format.xml  { render :xml => @groups }
      format.json  { render :json => @groups }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def new
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def destroy
    @group.destroy

    respond_to do |format|
      format.html
      format.xml  { head :ok }
    end
  end

end
