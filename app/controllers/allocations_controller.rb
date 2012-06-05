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

    render :layout => false
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
        format.json { render json: @allocation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /allocations/1
  # PUT /allocations/1.json
  def update
    @allocation = Allocation.find(params[:id])

    respond_to do |format|
      if @allocation.update_attributes(params[:allocation])
        format.html { redirect_to @allocation, notice: 'Allocation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @allocation.errors, status: :unprocessable_entity }
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
        format.html { redirect_to(offers_showoffersbyuser_url, :notice => message) }
        format.json { head :ok }
      else
        format.html { redirect_to(offers_showoffersbyuser_url, :alert => message) }
        format.json { head :error }
      end
    end
  end

  # pede reativacao de matricula (alocacao)
  def reactivate
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Pending_Reactivate

    message = ''
    if @allocation.save
      message = t(:enrollm_request_message)
    end

    respond_to do |format|
      format.html { redirect_to(offers_showoffersbyuser_url, :notice => message) }
      format.xml  { head :ok }
    end
  end

  # pede matricula (alocacao)
  def send_request
    if params[:tagid] && params[:userid] && (student_profile!='')

      # se havia status anterior, reativa
      if params[:id]
        @allocation = Allocation.find(params[:id])
        @allocation.status = Allocation_Pending_Reactivate
      else
        # senao gera novo pedido (alocacao) de matricula
        @allocation = Allocation.new
        @allocation.user_id = params[:userid]
        @allocation.allocation_tag_id = params[:tagid]
        @allocation.profile_id = student_profile
        @allocation.status = Allocation_Pending
      end

      message = ''
      if @allocation.save
        message = t(:enrollm_request_message)
      end

      respond_to do |format|
        format.html { redirect_to(offers_showoffersbyuser_url, :notice => message) }
        format.xml  { head :ok }
      end
    end
  end

end
