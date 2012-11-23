class DiscussionsController < ApplicationController

  include EditionHelper

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
    @offer_id, @group_id, @allocation_tags_ids = params[:offer_id], params[:group_id], params[:allocation_tags_ids]
    @discussion = Discussion.new
    render :layout => false
  end

  def create
    @offer_id, @group_id, @allocation_tags_ids  = params[:offer_id], params[:group_id], params[:allocation_tags_ids]
    @discussion, @schedule = Discussion.new(params[:discussion]), Schedule.new(:start_date => params["start_date"], :end_date => params["end_date"]) # utilizados para validação
    offer                  = Offer.find(@offer_id) # utilizado para validação
    @group_and_offer_info  = group_and_offer_info(@group_id, @offer_id) # informação na página

    begin

      raise  "validation_error" unless @discussion.valid?
      raise "date_range_error" if @schedule.start_date < offer.start_date or @schedule.end_date > offer.end_date # período escolhido deve estar dentro do período da oferta

      ActiveRecord::Base.transaction do
        @allocation_tags_ids.split(" ").each do |allocation_tag_id|
          schedule = Schedule.create!(:start_date => params["start_date"], :end_date => params["end_date"])
          Discussion.create!(:name => @discussion.name, :description => @discussion.description, :schedule_id => schedule.id, :allocation_tag_id => allocation_tag_id.to_i)
        end
      end
      @discussions = Discussion.all_by_allocation_tags(@allocation_tags_ids)

      respond_to do |format|
        format.html {render :list, :layout => false}
      end

    rescue Exception => error
      @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors])) if error.message == t(:existing_name, :scope => [:discussion, :errors])

      if error.message == "date_range_error"
        @schedule_error = t(:offer_period, :scope => [:discussion, :errors], :start => l(offer.start_date, :formats => :default), :end => l(offer.end_date, :formats => :default))
      end
      @schedule_error = @schedule.errors.full_messages[0] unless @schedule.valid?

      respond_to do |format|
        format.html { render :new, :layout => false}
      end

    end # begin/rescue
  end

  def list
    @offer_id, @group_id, @allocation_tags_ids  = params[:offer_id], params[:group_id], params[:allocation_tags_ids]
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)
    # @discussions          = Discussion.all_by_allocation_tags(@allocation_tags_ids)
    @discussions = Discussion.where(allocation_tag_id: @allocation_tags_ids)

    render :layout => false
  end

  def edit
    @offer_id, @group_id, @allocation_tags_ids  = params[:offer_id], params[:group_id], params[:allocation_tags_ids]
    render :layout => false
  end

  def update
    @offer_id, @group_id, @allocation_tags_ids  = params[:offer_id], params[:group_id], params[:allocation_tags_ids]
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)
    @discussions          = Discussion.all_by_allocation_tags(@allocation_tags_ids)

    unless @discussion.closed?
      
      offer, @schedule = Offer.find(@offer_id), Schedule.new(:start_date => params[:start_date], :end_date => params[:end_date]) # utilizados para validação
      schedule         = @discussion.schedule
      
      begin
        
        raise  "validation_error" unless @discussion.valid? and @schedule.valid?
        raise "date_range_error" if @schedule.start_date < offer.start_date or @schedule.end_date > offer.end_date # período escolhido deve estar dentro do período da oferta

        schedule.update_attributes!(:start_date => params["start_date"], :end_date => params["end_date"])
        @discussion.update_attributes!(params[:discussion])
        @discussions = Discussion.all_by_allocation_tags(@allocation_tags_ids)
        respond_to do |format|
          format.html {render :list, :layout => false}
        end

      rescue Exception => error
        @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors])) if error.message == t(:existing_name, :scope => [:discussion, :errors])

        if error.message == "date_range_error"
          @schedule_error = t(:offer_period, :scope => [:discussion, :errors], :start => l(offer.start_date, :formats => :default), :end => l(offer.end_date, :formats => :default))
        else 
          @schedule_error = @schedule.errors.full_messages[0] unless @schedule.valid?
        end

        respond_to do |format|
          format.html { render :edit, :layout => false}
        end
      end

    else  
      @access_denied = true
      respond_to do |format|
        format.html { render :list, :layout => false }
      end
    end

  end

  def destroy
    @offer_id, @group_id, @allocation_tags_ids  = params[:offer_id], params[:group_id], params[:allocation_tags_ids]
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)

    if @discussion.destroy
      @discussions = Discussion.all_by_allocation_tags(@allocation_tags_ids)
    else
      @error_deletion = @discussion.errors.full_messages[0]
      @discussions    = Discussion.all_by_allocation_tags(@allocation_tags_ids)
    end
    
    render :list, :layout => false
  end

end
