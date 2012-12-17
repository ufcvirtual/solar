class DiscussionsController < ApplicationController

  include EditionHelper

  layout false, :except => :index # define todos os layouts do controller como falso

  authorize_resource :only => [:index]
  load_and_authorize_resource :only => [:edit]

  before_filter :prepare_for_group_selection, only: :index

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
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    authorize! :new, Discussion, :on => @allocation_tags_ids
    
    @discussion          = Discussion.new
  end

  def create
    @allocation_tags_ids   = params[:allocation_tags_ids].split(" ")
    @discussion, @schedule = Discussion.new(params[:discussion]), Schedule.new(:start_date => params["start_date"], :end_date => params["end_date"]) # utilizados para validação

    begin

      authorize! :create, Discussion, :on => @allocation_tags_ids

      raise "validation_error" unless (not @discussion.nil?) and @discussion.valid? 
      @allocation_tags_ids.each do |allocation_tag_id|
        allocation_tag  = AllocationTag.find(allocation_tag_id.to_i)
        offer           = allocation_tag.offer || allocation_tag.group.offer
        raise "date_range_error" if @schedule.start_date < offer.start_date or @schedule.end_date > offer.end_date # período escolhido deve estar dentro do período da oferta
      end

      ActiveRecord::Base.transaction do
        @allocation_tags_ids.each do |allocation_tag_id|
          schedule = Schedule.create!(:start_date => params["start_date"], :end_date => params["end_date"])
          Discussion.create!(:name => @discussion.name, :description => @discussion.description, :schedule_id => schedule.id, :allocation_tag_id => allocation_tag_id.to_i)
        end
      end

      respond_to do |format|
        format.html {render :action => :list, :status => 200}
      end

    rescue CanCan::AccessDenied

      respond_to do |format|
        format.html { render :status => 500}
      end  

    rescue Exception => error

      @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors])) if error.message == t(:existing_name, :scope => [:discussion, :errors])

      if error.message == "date_range_error"
        @schedule_error = t(:offer_period, :scope => [:discussion, :errors], :start => l(offer.start_date, :formats => :default), :end => l(offer.end_date, :formats => :default))
      end
      @schedule_error = @schedule.errors.full_messages[0] unless @schedule.valid?

      respond_to do |format|
        format.html { render :new, :status => 200} # envia com status de sucesso, mas no ajax há verificação para erros no formulário
      end    

    end # begin/rescue
  end

  def list
    @allocation_tags_ids = params[:allocation_tags_ids]
    authorize! :list, Discussion, :on => params[:allocation_tags_ids]
    @discussions         = Discussion.where(allocation_tag_id: @allocation_tags_ids)
  end

  def edit
    @allocation_tags_ids  = params[:allocation_tags_ids]
  end

  def update
    @discussion          = Discussion.find(params[:id])
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")

    unless @discussion.closed?
      
      offer, @schedule = @discussion.allocation_tag.offer, Schedule.new(:start_date => params[:start_date], :end_date => params[:end_date]) # utilizados para validação
      schedule         = @discussion.schedule
      
      begin

        authorize! :update, @discussion
        
        raise  "validation_error" unless @discussion.valid? and @schedule.valid?
        @allocation_tags_ids.each do |allocation_tag_id| # como pode haver mais de uma allocation_tag_id, é necessário verificar cada uma
          allocation_tag  = AllocationTag.find(allocation_tag_id.to_i)
          offer           = allocation_tag.offer || allocation_tag.group.offer
          raise "date_range_error" if @schedule.start_date < offer.start_date or @schedule.end_date > offer.end_date # período escolhido deve estar dentro do período da oferta
        end

        schedule.update_attributes!(:start_date => params["start_date"], :end_date => params["end_date"])
        @discussion.update_attributes!(params[:discussion])

        respond_to do |format|
          format.html {render :list, :status => 200}
        end

      rescue Exception => error
        @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors])) if error.message == t(:existing_name, :scope => [:discussion, :errors])

        if error.message == "date_range_error"
          @schedule_error = t(:offer_period, :scope => [:discussion, :errors], :start => l(offer.start_date, :formats => :default), :end => l(offer.end_date, :formats => :default))
        else 
          @schedule_error = @schedule.errors.full_messages[0] unless @schedule.valid?
        end

        respond_to do |format|
          format.html { render :edit, :status => 200} # envia com status de sucesso, mas no ajax há verificação para erros no formulário
        end
      end

    else  
      respond_to do |format|
        format.html { render :list, :status => 500}
      end
    end

  end


  def destroy
    discussion = Discussion.find(params[:id])
    
    begin
      authorize! :destroy, discussion
      raise "error" unless discussion.destroy
      @allocation_tags_ids = params[:allocation_tags_ids]
      respond_to do |format|
        format.html { render :list, :satus => 200 }
      end
    rescue Exception => error
      respond_to do |format|
        format.html { render :satus => 500 }
      end
    end
    
  end


end
