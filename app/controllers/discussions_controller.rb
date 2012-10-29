class DiscussionsController < ApplicationController

authorize_resource :only => [:index, :new, :create, :list]
load_and_authorize_resource :only => [:edit, :update, :destroy]

  def index
    begin
      allocation_tag_id = (active_tab[:url].include?('allocation_tag_id')) ? active_tab[:url]['allocation_tag_id'] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @discussions      = Discussion.all_by_allocation_tags(AllocationTag.find_related_ids(allocation_tag_id))
    rescue
      @discussions      = []
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @discussions }
      format.json  { render :json => @discussions }
    end
  end

  def new
    # @offer_id   = params[:offer_id]
    # @group_id   = params[:group_id]
    @offer_id   = 3
    @group_id   = "all"
    
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)

    @discussion = Discussion.new


    render :layout => false
  end

  def create
    @discussion = Discussion.new(params[:discussion])
    @schedule   = Schedule.new(:start_date => params["start_date"], :end_date => params["end_date"])
    @offer_id, @group_id = params["offer_id"], params["group_id"]

    begin 

      if @group_id == 0 # nenhum
        allocations_tags_ids = [AllocationTag.find_by_offer_id(@offer_id).id]
      elsif @group_id == "all" # todos
        allocations_tags_ids = Group.find_all_by_offer_id_and_status(@offer_id, true).collect{|group| AllocationTag.find_by_group_id(group.id).id }
      else # algum específico
        allocations_tags_ids = [AllocationTag.find_by_group_id(@group_id).id]
      end

      ActiveRecord::Base.transaction do
        allocations_tags_ids.each do |allocation_tag_id|
          schedule   = Schedule.create!(:start_date => params["start_date"], :end_date => params["end_date"])
          discussion = Discussion.create!(:name => @discussion.name, :description => @discussion.description, :schedule_id => schedule.id, :allocation_tag_id => allocation_tag_id.to_i)
        end
      end

      redirect_to list_discussions_url, :notice => "congratz"

    rescue Exception => error
      if @discussion.valid?
        # se é válido e deu erro, problema tá no nome único ou no schedule
        if @schedule.valid?
          # se é válido e deu erro, problema tá no nome único
          ########### ALTERAR INTERNACIONALIZAÇÃO \/
          @discussion.errors.add(:name, t(:existing_name_error, :scope => [:assignment, :group_assignments]))
        else
          @schedule_error = @schedule.errors.full_messages[0]
        end
      end
      render :action => "new"
    end

  end

  def list
    # @offer_id, @group_id = params["offer_id"], params["group_id"]
    @offer_id, @group_id = 3, "all"
    
    if @group_id == 0 # nenhum
      allocations_tags_ids = [AllocationTag.find_by_offer_id(@offer_id).id]
    elsif @group_id == "all" # todos
      allocations_tags_ids = Group.find_all_by_offer_id_and_status(@offer_id, true).collect{|group| AllocationTag.find_by_group_id(group.id).id }
      group_code = "todas as turmas"
    else # algum específico
      allocations_tags_ids = [AllocationTag.find_by_group_id(@group_id).id]
      group_code  = Group.find(@group_id).code
    end

    offer_semester = Offer.find(@offer_id).semester
    @turma         = group_code
    @oferta        = offer_semester
    @discussions   = Discussion.all_by_allocation_tags(allocations_tags_ids).sort_by{|a| a.schedule.start_date}
  end

  def edit
    render :layout => false
  end

  def update
    schedule = @discussion.schedule

    if @discussion.can_edit?
      begin
        schedule.update_attributes!(:start_date => params["from_date"], :end_date => params["until_date"])
        @discussion.update_attributes!(params[:curriculum_unit])
        redirect_to list_discussions_url, :notice => "congratz"
      rescue Exception => error
        render :action => "edit"
      end
    else
      redirect_to list_discussions_url, :alert => "Nao pode editar"
    end

  end

  def destroy
    schedule = @discussion.schedule
    if @discussion.destroy
      schedule.destroy
      redirect_to list_discussions_url, :notice => "congratz"
    else
      redirect_to list_discussions_url, :alert => @discussion.errors.full_messages[0]
    end
  end

end
