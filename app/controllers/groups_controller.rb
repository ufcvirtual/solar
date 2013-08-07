class GroupsController < ApplicationController

  layout false, except: [:index]

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
    @offer = Offer.find_by_curriculum_unit_id_and_semester_id_and_course_id(params[:curriculum_unit_id], params[:semester_id], params[:course_id])

    begin
      authorize! :list, Group, on: [@offer.allocation_tag.id]

      @groups = @offer.groups.order("status DESC, code")
      render partial: 'groups_checkboxes', locals: { groups: @groups } if params[:checkbox]
    rescue CanCan::AccessDenied
      render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
    end
  end

  def new
    authorize! :create, Group
    offer  = Offer.find_by_curriculum_unit_id_and_semester_id_and_course_id(params[:curriculum_unit_id], params[:semester_id], params[:course_id])
    @group = Group.new offer_id: offer.try(:id)
  end

  def edit
    authorize! :update, Group
    @group = Group.find(params[:id])
  end

  def create
    params[:group][:user_id] = current_user.id
    @group = Group.new(params[:group])
    authorize! :create, Group, on: [@group.offer.allocation_tag.id]

    if @group.save
      render json: {success: true, notice: t(:created, scope: [:groups, :success])}
    else
      render :new
    end
  end

  def update
    @group = Group.where(id: params[:id].split(","))
    authorize! :update, Group, on: [@group.first.offer.allocation_tag.id]

    if params[:multiple]
      @group.update_all(status: params[:status])
      render json: {success: true, notice: t(:updated, scope: [:groups, :success])}
    else
      @group = @group.first
      if @group.update_attributes(params[:group])
        render json: {success: true, notice: t(:updated, scope: [:groups, :success])}
      else
        render :edit
      end
    end
  end

  def destroy
    @group = Group.where(id: params[:id].split(","))
    authorize! :destroy, Group, on: [@group.first.offer.allocation_tag.id]

    Group.transaction do 
      begin
        @group.each do |group|
          raise "erro" unless group.destroy
        end
        render json: {success: true, notice: t(:deleted, scope: [:groups, :success])}
      rescue
        render json: {success: false, alert: t(:deleted, scope: [:groups, :error])}, status: :unprocessable_entity
      end
    end
  end

end
