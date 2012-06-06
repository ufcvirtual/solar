class AllocationsController < ApplicationController

  # load_and_authorize_resource

  # GET /allocations
  # GET /allocations.json
  def index
    @allocations = Allocation.enrollments(params.select { |k, v| ['offer_id', 'group_id'].include?(k) })

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @allocations }
    end
  end

  # GET /allocations/1
  # GET /allocations/1.json
  def show
    @allocation = Allocation.find(params[:id])

    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @allocation }
    end
  end

  # GET /allocations/new
  # GET /allocations/new.json
  # def new
  #   @allocation = Allocation.new

  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.json { render json: @allocation }
  #   end
  # end

  # GET /allocations/1/edit
  def edit
    @allocation = Allocation.find(params[:id])

    relateds = AllocationTag.find_related_ids(@allocation.allocation_tag_id)

    offers = AllocationTag.where("id in (?) and offer_id is not null", relateds).map {|at| at.offer_id }
    @groups = Group.where(:offer_id => offers)

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  # POST /allocations
  # POST /allocations.json
  def create
    @allocation = Allocation.new(params[:allocation])

    respond_to do |format|
      if @allocation.save
        format.html { redirect_to @allocation, notice: 'Allocation was successfully created.' }
        format.json { render json: @allocation, status: :created, location: @allocation }
      else
        format.html { render action: "new" }
        format.json { render json: @allocation.errors, status: :error }
      end
    end
  end

  # PUT /allocations/1
  # PUT /allocations/1.json
  def update
    params[:allocation][:allocation_tag_id] = AllocationTag.find_by_group_id(params[:allocation].delete(:group_id)).id if params[:allocation].include?(:group_id)
    @allocation = Allocation.find(params[:id])

    respond_to do |format|
      if @allocation.update_attributes(params[:allocation])
        format.html { render action: "show", layout: false }
        format.json { render json: {:success => true} }
      else
        format.html { render action: "edit", layout: false }
        format.json { render json: @allocation.errors, status: :error }
      end
    end
  end

  # DELETE /allocations/1/cancel
  # DELETE /allocations/1/cancel_request
  def destroy
    authorize! :cancel, Allocation if not params.include?(:type)
    authorize! :cancel_request, Allocation if params.include?(:type) and params[:type] == 'request'

    @allocation = Allocation.find(params[:id])

    begin
      error = false
      if params.include?(:type) and params[:type] == 'request' and @allocation.status == Allocation_Pending
        @allocation.destroy
        message = t(:enrollm_request_cancel_message)
      else
        @allocation.status = Allocation_Cancelled
        @allocation.save!
        message = t(:enrollm_cancelled_message)
      end
    rescue Exception => e
      message = t(:enrollm_not_cancelled_message)
      error = true
    end

    respond_to do |format|
      unless error
        format.html { redirect_to(offers_showoffersbyuser_url, notice: message) }
        format.json { head :ok }
      else
        format.html { redirect_to(offers_showoffersbyuser_url, alert: message) }
        format.json { head :error }
      end
    end
  end

  def reactivate
    authorize! :reactivate, Allocation

    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Pending_Reactivate

    respond_to do |format|
      if @allocation.save
        format.html { redirect_to(offers_showoffersbyuser_url, notice: t(:enrollm_request_message)) }
        format.json { head :ok }
      else
        format.html { redirect_to(offers_showoffersbyuser_url, alert: t(:enrollm_request_message_error)) }
        format.json { head :error }
      end
      
    end
  end

  def send_request
    authorize! :send_request, Allocation

    if params.include?(:tagid) and params.include?(:userid) and (student_profile != '')
      if params.include?(:id) # se havia status anterior, reativa
        @allocation = Allocation.find(params[:id])
        @allocation.status = Allocation_Pending_Reactivate
      else
        @allocation = Allocation.new({
          :user_id => params[:userid],
          :allocation_tag_id => params[:tagid],
          :profile_id => student_profile,
          :status => Allocation_Pending
        })
      end

      respond_to do |format|
        if @allocation.save
          format.html { redirect_to(offers_showoffersbyuser_url, notice: t(:enrollm_request_message)) }
          format.json { head :ok }
        else
          format.html { redirect_to(offers_showoffersbyuser_url, alert: t(:enrollm_request_message_error)) }
          format.json { head :error }
        end
      end
    end
  end

end
