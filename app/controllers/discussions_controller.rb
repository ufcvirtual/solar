class DiscussionsController < ApplicationController

  layout false, except: :index # define todos os layouts do controller como falso

  authorize_resource only: :index
  load_and_authorize_resource only: :edit

  before_filter :prepare_for_group_selection, only: :index

  def index
    begin
      allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
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

  # SolarMobilis
  # GET /groups/:group_id/discussions/mobilis_list.json
  def mobilis_list
    begin
      allocation_tag_id = (active_tab[:url].include?(:allocation_tag_id)) ? active_tab[:url][:allocation_tag_id] : AllocationTag.find_by_group_id(params[:group_id] || []).id
      @discussions      = Discussion.all_by_allocation_tags(AllocationTag.find_related_ids(allocation_tag_id))
    rescue
      @discussions      = []
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @discussions }
      format.json  { render :json => {discussions: @discussions } }
    end
  end

  def new
    @allocation_tags_ids = [params[:allocation_tags_ids]].flatten
    authorize! :new, Discussion, on: @allocation_tags_ids
    @discussion          = Discussion.new
  end

  def create
    @allocation_tags_ids = [params[:allocation_tags_ids]].flatten
    @discussion = Discussion.new
    @schedule = Schedule.new

    authorize! :create, Discussion, on: @allocation_tags_ids  
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

      render json: {success: true, notice: t(:created, scope: [:offers, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception => err
      error = []
      error << @schedule.errors.full_messages.join(', ') unless @schedule.errors.empty?
      error << @discussion.errors.messages[:final_date_presence] unless @discussion.errors.empty?
      @error = error.compact.join(', ')

      render :new
    end # rescue
  end

  def list
    @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      authorize! :list, Discussion, on: @allocation_tags_ids
      @discussions = Discussion.where(allocation_tag_id: @allocation_tags_ids)
    rescue
      render :nothing => true, :status => 500
    end
  end

  def edit
    @allocation_tags_ids = [params[:allocation_tags_ids]].flatten
    authorize! :edit, Discussion, on: @allocation_tags_ids  
  end

  def update
    @allocation_tags_ids = [params[:allocation_tags_ids]].flatten
    authorize! :update, Discussion, on: @allocation_tags_ids  
      
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
   
      render json: {success: true, notice: t(:updated, scope: [:offers, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception => err
      error = []
      error << @schedule.errors.full_messages.join(', ') unless @schedule.errors.empty?
      error << @discussion.errors.messages[:final_date_presence] unless @discussion.errors.empty?
      @error = error.compact.join(', ')

      render :edit
    end 

  end

  def destroy
    discussions = Discussion.where(id: params[:id].split(","))
    authorize! :destroy, Discussion, on: discussions.map(&:allocation_tag_id).uniq.flatten

    has_posts = false
    begin
      Discussion.transaction do
        raise has_posts = true if discussions.map(&:can_destroy?).include?(false)
        discussions.destroy_all
      end

      render json: {success: true, notice: t(:deleted, scope: [:discussion, :success])}
    rescue
      alert_message = (has_posts ? t(:discussion_with_posts, :scope => [:discussion, :errors]) : t(:deleted, scope: [:discussion, :error]))
      render json: {success: false, alert: alert_message}, status: :unprocessable_entity
    end
    
  end

end
