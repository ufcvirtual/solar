class GroupsController < ApplicationController

  layout false, only: [:new, :create, :edit, :update]

  # Webservice utilizado pelo Mobilis
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

  # Webservice utilizado pelo componente de publicação
  def list
    authorize! :list, Group

    if params.include?(:edition) and params[:edition] # apenas para ofertas
      @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
      @offer = AllocationTag.find(@allocation_tags_ids).first.offer
      @groups = @offer.groups
    else
      groups_to_list_on_filter
    end

    respond_to do |format|
      format.html { render layout: !params[:layout] }
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


  private

    def groups_to_list_on_filter
      al                 = current_user.allocations.where(status: Allocation_Activated)
      my_direct_groups   = al.map(&:group).compact
      groups_by_offers   = al.map(&:offer).compact.map(&:groups).uniq
      groups_by_courses  = al.map(&:course).compact.map(&:groups).uniq
      groups_by_ucs      = al.map(&:curriculum_unit).compact.map(&:groups).uniq
      
      @groups            = [my_direct_groups + groups_by_offers + groups_by_courses + groups_by_ucs].flatten.compact.uniq
      @groups.sort! { |a,b| a.code <=> b.code }

      if params.include?(:curriculum_unit_id)
        ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
        @groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
      end

      if params.include?(:search)
        params[:search].strip!
        @groups = @groups.select { |group| group.code.downcase.include?(params[:search].downcase) }

        all_allocation_tag_ids = Array.new(@groups.count)
        params[:chained_filter] = params.include?(:chained_filter) ? params[:chained_filter].split(',').compact : []

        @groups.each_with_index do |group,i|
          respects_chained_filter = false

          group[:allocation_tag_id] = [group.allocation_tag.id]

          respects_chained_filter = true if (params[:chained_filter].empty? or params[:chained_filter].include?(group.allocation_tag.id.to_s) or params[:chained_filter].include?(group.offer.allocation_tag.id.to_s) or params[:chained_filter].include?(group.course.allocation_tag.id.to_s))
          all_allocation_tag_ids[i] = group[:allocation_tag_id] if respects_chained_filter

          @groups[i] = nil unless respects_chained_filter
        end
        @groups = @groups.compact
        
        reference_code = nil
        reference_index = -1
        @groups.each_with_index do |group, i|
          if reference_code == group.code
            @groups[reference_index][:allocation_tag_id] += group[:allocation_tag_id]
            @groups[reference_index].status = nil
            @groups[reference_index].offer_id = nil
            @groups[reference_index].id = nil
            @groups[i] = nil
          else
            reference_code = group.code
            reference_index = i
          end
        end
        
        @groups = @groups.compact
        
        @groups.each do |group|
          group.code << " (#{group[:allocation_tag_id].count.to_s})" if (group[:allocation_tag_id].count > 1) 
        end
        
        all_allocation_tag_ids = all_allocation_tag_ids.compact.flatten

        optionAll = {:code => '...' << params[:search] << "... (#{all_allocation_tag_ids.count})", :allocation_tag_id => all_allocation_tag_ids, :name =>"*"}
        @groups << optionAll
      end
    end

end
