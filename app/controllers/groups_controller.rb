class GroupsController < ApplicationController

  # load_and_authorize_resource

  def index
    @groups = current_user.groups

    if params.include?(:curriculum_unit_id)
      ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
      @groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
    end

    if params.include?(:search)
      @groups = @groups.select { |group| group.code.downcase.include?(params[:search].downcase) }
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester} } }
      format.json  { render :json => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester} } }
    end
  end

  def new
    @group = Group.new

    ## verificar o que carregar de dados => ainda nao pronto

    @offers = Offer.all
    @courses = Course.all
    @curriculum_units = CurriculumUnit.all

    render layout: false
  end

  def edit
    @group = Group.find(params[:id])

    ## verificar o que carregar de dados => ainda nao pronto

    @edit = true
    @offers = [@group.offer]
    @curriculum_units = [@offers.first.curriculum_unit]
    @courses = Course.all

    render layout: false
  end

  def create
    params[:group][:user_id] = current_user.id
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        format.html { redirect_to groups_url, notice: t(:successfully_created, :register => @group.code) }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    @group = Group.find(params[:id])

    # raise "#{params}"

    if @group.update_attributes(params[:group])
      redirect_to groups_url, notice: t(:successfully_updated, :register => @group.code)
    else
      redirect_to edit_group_url(@group), :alert => @group.errors
    end
  end

  def destroy
    begin
      @group = Group.find(params[:id])
      if @group.destroy
        redirect_to groups_url, :notice => t(:successfully_deleted, :register => @group.code_semester)
      else
        redirect_to groups_url, :alert => t(:cant_delete, :register => @group.code_semester)
      end
    rescue
      redirect_to groups_url, :alert => t(:cant_delete, :register => @group.code_semester)
    end
  end

end
