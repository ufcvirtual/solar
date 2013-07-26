class GroupsController < ApplicationController

  layout false, only: [:list, :new, :create, :edit, :update]

  # Mobilis
  def index
    @groups = current_user.groups

    if params.include?(:curriculum_unit_id)
      ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
      @groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } }
      format.json  { render :json => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } }
    end
  end

  # Edicao
  def list
    authorize! :list, Group

    # curriculum_unit_id, course_id, semester_id
    query = []
    query << "offers.curriculum_unit_id = #{params[:curriculum_unit_id]}" unless params[:curriculum_unit_id].blank?
    query << "offers.course_id = #{params[:course_id]}" unless params[:course_id].blank?
    query << "offers.semester_id = #{params[:semester_id]}" unless params[:semester_id].blank?

    @groups = []
    @groups = Group.joins(offer: :semester).where(query.join(" AND ")) unless query.empty?

    respond_to do |format|
      format.html
      format.xml { render xml: @groups }
      format.json  { render json: @groups }
    end
  end

  def new
    authorize! :create, Group

    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @group = Group.new
    @offer = AllocationTag.find(@allocation_tags_ids).first.offer
  end

  def edit
    authorize! :update, Group

    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @group = Group.find(params[:id])
    @offer = @group.offer
  end

  def create
    authorize! :create, Group

    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @group = Group.new(params[:group])

    begin
      @group.save!
      render nothing: true
    rescue
      @offer = Offer.find(params[:group][:offer_id])
      render :new
    end
  end

  def update
    authorize! :update, Group

    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @group = Group.find(params[:id])

    begin
      @group.update_attributes(params[:group])
      if params.include?(:redirect) and params[:redirect]
        redirect_to list_to_edit_groups_path(allocation_tags_ids: @group.offer.allocation_tag.id), :notice => t(:successfully_updated, :register => @group.code)
      else
        raise unless @group.valid?
        render nothing: true
      end
    rescue
      @offer = @group.offer
      render :new
    end
  end

  def destroy
    authorize! :destroy, Group

    @group = Group.find(params[:id])

    if @group.destroy
      redirect_to list_to_edit_groups_path(allocation_tags_ids: @group.offer.allocation_tag.id), :notice => t(:successfully_deleted, :register => @group.code_semester)
    else
      redirect_to list_to_edit_groups_path(allocation_tags_ids: @group.offer.allocation_tag.id), :alert => t(:cant_delete, :register => @group.code_semester)
    end
  end

end
