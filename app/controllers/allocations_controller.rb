class AllocationsController < ApplicationController

  authorize_resource :except => [:destroy]

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

  # GET /allocations/1/edit
  def edit
    @allocation = Allocation.find(params[:id])

    ats = AllocationTag.where("id in (?) and (group_id is not null or offer_id is not null)", @allocation.allocation_tag.related)
    @groups = Group.where("id in (?) or offer_id in (?)", ats.map(&:group_id).compact.uniq, ats.map(&:offer_id).compact.uniq)

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  # POST /allocations
  # POST /allocations.json
  def create
    if params.include?(:allocation_tag_id) and params.include?(:user_id) and (student_profile != '')
      if params.include?(:id) # se havia status anterior, reativa
        @allocation = Allocation.find(params[:id])
        @allocation.status = Allocation_Pending_Reactivate
      else
        @allocation = Allocation.new({
          :user_id => params[:user_id],
          :allocation_tag_id => params[:allocation_tag_id],
          :profile_id => student_profile,
          :status => Allocation_Pending
        })
      end

      respond_to do |format|
        if @allocation.save
          format.html { redirect_to(offers_showoffersbyuser_url, notice: t(:enrollm_request_message)) }
          format.json { render json: @allocation, status: :created }
        else
          format.html { redirect_to(offers_showoffersbyuser_url, alert: t(:enrollm_request_message_error)) }
          format.json { render json: @allocation.errors, status: :error }
        end
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
        format.json { render json: {:status => "ok"} }
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

end
