class DiscussionsController < ApplicationController

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
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    authorize! :create, Discussion, :on => @allocation_tags_ids

    @discussion = Discussion.new
    @schedule = Schedule.new
    begin
      Discussion.transaction do
        @allocation_tags_ids.each do |allocation_tag_id|
          @schedule = Schedule.new(start_date: params[:start_date], end_date: params[:end_date])
          @discussion = Discussion.new(params[:discussion]) #Setar a discussion antes de salvar schedule, caso aconteça erro, não perder as informações.
          @schedule.save!

          @discussion.allocation_tag_id = allocation_tag_id
          @discussion.schedule = @schedule
          @discussion.save!
        end
      end

      render :list
    rescue Exception => err
      error = []
      error << @schedule.errors.full_messages.join(', ') unless @schedule.errors.empty?
      error << @discussion.errors.messages[:final_date_presence] unless @discussion.errors.empty?
      @error = error.compact.join(', ')

      render :new
    end # rescue
  end

  def list
    @allocation_tags_ids = params[:allocation_tags_ids].uniq

    begin
      authorize! :list, Discussion, :on => @allocation_tags_ids
      @discussions = Discussion.where(allocation_tag_id: @allocation_tags_ids)
    rescue
      respond_to do |format|
        format.html { render :nothing => true, :status => 500  }
      end
    end
  end

  def edit
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
  end

  def update
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    authorize! :update, Discussion, :on => @allocation_tags_ids  
      
    @discussion = Discussion.find(params[:id])
    @schedule = Schedule.find(@discussion.schedule_id)
    
    begin
      Discussion.transaction do
        # Setando valores digitados de discussion e schedule pelo usuário para que não sejam perdidos, caso haja alguma exceção
        @discussion.name = params[:discussion][:name]
        @discussion.description = params[:discussion][:description]
        @schedule.start_date = params[:start_date]
        @schedule.end_date = params[:end_date] 

        @schedule.update_attributes!(start_date: params[:start_date], end_date: params[:end_date])
        @discussion.update_attributes!(params[:discussion])
      end
   
      render :list
    rescue Exception => err
      error = []
      error << @schedule.errors.full_messages.join(', ') unless @schedule.errors.empty?
      error << @discussion.errors.messages[:final_date_presence] unless @discussion.errors.empty?
      @error = error.compact.join(', ')

      render :edit
    end 

  end

  def destroy
    begin
      @discussion = Discussion.find(params[:id])
      authorize! :destroy, @discussion, on: params[:allocation_tags_ids].split(" ")

      success = false
      if @discussion.destroy
        success = true
      else
        raise @discussion.errors.full_messages.join(' ')
      end
    rescue Exception => e
      msg = e.message
      success = false
    end

    render json: {success: success, msg: msg}, status: success ? :ok : :unprocessable_entity
  end

end
