include AllocationsHelper

class AllocationsController < ApplicationController

  authorize_resource :except => [:destroy]

  # GET /allocations
  # GET /allocations.json
  def index
    groups = current_user.groups.map(&:id)
    p = params.select { |k, v| ['offer_id', 'group_id', 'status'].include?(k) }
    p['group_id'] = (params.include?('group_id') and groups.include?(params['group_id'].to_i)) ? [params['group_id']] : groups.flatten.compact.uniq

    @allocations = Allocation.enrollments(p)

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
    ids = params[:id].split(',')
    @multiple = (ids.length > 1 or (params.include?('multiple') and params['multiple'] == 'yes'))
    @allocation = Allocation.find(ids)
    @status_hash = status_hash_of_allocation(@allocation.first.status)
    @users = @allocation.map(&:user).uniq.map(&:name)

    allocation = @allocation.first

    if @change_group = (not [Allocation_Cancelled, Allocation_Rejected].include?(allocation.status))
      @groups = Group.where(:offer_id => allocation.group.offer_id) # transicao entre grupos apenas da mesma oferta
    else
      @groups = allocation.allocation_tag.group
    end

    @allocation = allocation unless @multiples

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
          format.html { redirect_to(enrollments_url, notice: t(:enrollm_request_message)) }
          format.json { render json: @allocation, status: :created }
        else
          format.html { redirect_to(enrollments_url, alert: t(:enrollm_request_message_error)) }
          format.json { render json: @allocation.errors, status: :error }
        end
      end
    end
  end

  # PUT /allocations/1
  # PUT /allocations/1.json
  def update
    params[:allocation][:allocation_tag_id] = AllocationTag.find_by_group_id(params[:allocation].delete(:group_id)).id if params[:allocation].include?(:group_id)
    allocation = Allocation.find(params[:id])

    # mudanca de turma - cancela allocation antiga e cria uma nova
    if params[:allocation].include?(:status) and params[:allocation][:status].to_i == Allocation_Activated.to_i and \
      params[:allocation].include?(:allocation_tag_id) and params[:allocation][:allocation_tag_id] != allocation.allocation_tag_id

      new_allocation = Allocation.new({
        :user_id => allocation.user_id,
        :allocation_tag_id => params[:allocation][:allocation_tag_id],
        :profile_id => allocation.profile_id,
        :status => params[:allocation][:status]
      })

      allocation.status = Allocation_Cancelled

      begin
        ActiveRecord::Base.transaction do
          allocation.save
          new_allocation.save
        end
        @allocation = new_allocation
        error = false
      rescue
        error = true
      end
    elsif allocation.update_attributes(params[:allocation])
      @allocation = allocation
      error = false
    else
      error = true
    end

    respond_to do |format|
      unless error
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
        format.html { redirect_to(enrollments_url, notice: message) }
        format.json { head :ok }
      else
        format.html { redirect_to(enrollments_url, alert: message) }
        format.json { head :error }
      end
    end
  end

  def reactivate
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Pending_Reactivate

    respond_to do |format|
      if @allocation.save
        format.html { redirect_to(enrollments_url, notice: t(:enrollm_request_message)) }
        format.json { head :ok }
      else
        format.html { redirect_to(enrollments_url, alert: t(:enrollm_request_message_error)) }
        format.json { head :error }
      end
    end
  end

  private
    def status_hash_of_allocation(allocation_status)
      case allocation_status
        when Allocation_Pending, Allocation_Pending_Reactivate
          status_hash.select {|k,v| [allocation_status, Allocation_Activated, Allocation_Rejected].include?(k)}
        when Allocation_Activated
          status_hash.select {|k,v| [allocation_status, Allocation_Cancelled].include?(k)}
        when Allocation_Cancelled, Allocation_Rejected
          # @change_group = false
          status_hash.select {|k,v| [allocation_status, Allocation_Activated].include?(k)}
      end
    end

end
