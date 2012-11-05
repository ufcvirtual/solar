include AllocationsHelper

class AllocationsController < ApplicationController

  authorize_resource :except => [:destroy, :search_users, :activate, :deactivate, :get_allocated]

  # GET /allocations/designates
  # GET /allocations/designates.json
  def new
    level = (params[:permissions]!="all") ? "responsible" : nil

    @allocations = Allocation.find(:all,
      :joins => [:profile, :user], 
      :conditions => ("#{level.nil?}") ? [("not(profiles.types & #{Profile_Type_Student})::boolean and not(profiles.types & #{Profile_Type_Basic})::boolean")] : [("(profiles.types & #{Profile_Type_Class_Responsible})::boolean")],
      :order => ["users.name","profiles.name"]) 

    respond_to do |format|
      flash[:notice] = t(:allocated_user) if params.include?(:notice)
      flash[:alert] = t(:allocated_user_error) if params.include?(:alert)
      format.html #
      format.json { render json: @allocations }
    end
  end

  # metodo chamado por ajax para buscar usuários para alocação
  def search_users
    text = URI.unescape(params[:data])
    @text_search = text
    @users = User.where("lower(name) ~ '#{text.downcase}'")
    @responsibles = Profile.where("(types & #{Profile_Type_Class_Responsible})::boolean")

    render :layout => false
  end

  # GET /allocations/enrollments
  # GET /allocations/enrollments.json
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
    @allocation   = Allocation.find(params[:id])
    @status_hash  = status_hash_of_allocation(@allocation.status)
    @change_group = (not [Allocation_Cancelled, Allocation_Rejected].include?(@allocation.status))

    # transicao entre grupos apenas da mesma oferta
    @groups = @change_group ? Group.where(:offer_id => @allocation.group.offer_id) : @allocation.group

    render layout: false
  end

  # POST /allocations
  # POST /allocations.json
  def create
    profile = (params.include?(:profile)) ? params[:profile] : student_profile
    status = (params.include?(:status)) ? params[:status] : Allocation_Pending
    total = 0
    corrects = 0

    if params.include?(:allocation_tag_id) and params.include?(:user_id) and (profile != '')
      if params.include?(:id) # se havia status anterior, reativa
        allocation = Allocation.find(params[:id])
        allocation.status = Allocation_Pending_Reactivate
        total = 1
        corrects = 1 if allocation.save
      else
        allocations = params[:allocation_tag_id].split(',')
        total = allocations.count()
        allocations.each { |id|
          allocation = Allocation.new({
            :user_id => params[:user_id],
            :allocation_tag_id => id,
            :profile_id => profile,
            :status => status
          })
          corrects = corrects + 1 if allocation.save
        }
      end

      if !params.include?(:status) and !params.include?(:profile)
        local = enrollments_url
        message_ok = t(:enrollm_request_message)
        message_error = t(:enrollm_request_message_error)
      #else
        #local = designates_allocations_url
        #message_ok = t(:allocated_user)
        #message_error = t(:allocated_user_error)
      end

      respond_to do |format|
        if corrects == total
          #format.html { redirect_to(local, notice: message_ok) } 
          format.html { redirect_to(enrollments_url, alert: t(:enrollm_request_message)) }
          format.json { render json: {:success => true, status: :ok } }
        else
          #format.html { redirect_to(local, alert: message_error) }
          format.html { redirect_to(enrollments_url, alert: t(:enrollm_request_message_error)) }
          format.json { render json: {:success => false, status: :ok } }
        end
      end
    end
  end

  # PUT /allocations/1
  # PUT /allocations/1.json
  def update
    allocation_tag_id = nil
    allocation_tag_id = Group.find(params[:allocation][:group_id]).allocation_tag.id if params.include?(:allocation) and params[:allocation].include?(:group_id)
    allocations       = Allocation.find(params[:id].split(','))
    allocation        = allocations.first
    new_status        = params.include?(:enroll) ? Allocation_Activated.to_i : ((params.include?(:allocation) and params[:allocation].include?(:status)) ? params[:allocation][:status] : 0)

    # verifica se existe mudanca de turma
      # se sim, todas as alocacoes serao canceladas e serao criadas novas com a nova turma
      # se não, somente o status das alocacoes serao modificados

    error = false
    begin
      ActiveRecord::Base.transaction do
        # mudanca de turma, nao existe chamada multipla para esta funcionalidade
        if ((not params.include?(:multiple)) and (not allocation_tag_id.nil?) and (allocation_tag_id != allocations.first.allocation_tag_id))
          # criando novas alocacoes e cancelando as antigas
          @allocation = Allocation.create!({:user_id => allocation.user_id, :allocation_tag_id => allocation_tag_id, :profile_id => allocation.profile_id, :status => params[:allocation][:status]})
          allocation.update_attributes(:status => Allocation_Cancelled) # cancelando a anterior

          Notifier.enrollment_accepted(@allocation.user.email, @allocation.group.code_semester).deliver if params[:allocation][:status].to_i == Allocation_Activated.to_i
        else # sem mudanca de turma
          @allocation = allocation
          allocations.each do |al|
            changed_status_to_accepted = ((al.status.to_i != Allocation_Activated.to_i) and (new_status.to_i == Allocation_Activated.to_i))
            al.update_attributes(:status => new_status)

            Notifier.enrollment_accepted(allocation.user.email, allocation.group.code_semester).deliver if changed_status_to_accepted
          end # allocations
        end # if
      end # transaction

      flash[:notice] = t(:enrollment_successful_update, :scope => [:allocations, :manage])
    rescue ActiveRecord::RecordNotUnique
      error = true
      msg_error = t(:student_already_in_group, :scope => [:allocations, :error])
    rescue Exception => e
      error = true
      msg_error = t(:enrollment_unsuccessful_update, :scope => [:allocations, :manage])
    end

    if error
      render :js => "javascript:flash_message('#{msg_error}', 'alert');"
    else
      respond_to do |format|
        format.html { render :action => :show, :layout => false }
        format.json { render :json => {:status => "ok"}  }
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

  def deactivate
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Cancelled
    @text_search = params[:text_search]

    respond_to do |format|
      if @allocation.save
        format.html { redirect_to(designates_allocations_url, notice: t(:deactivated_user)) }
        format.json { head :ok }
      else
        format.html { redirect_to(designates_allocations_url, alert: t(:deactivated_user_error)) }
        format.json { head :error }
      end
    end
  end

  def activate
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Activated

    respond_to do |format|
      if @allocation.save        
        format.html { redirect_to(designates_allocations_url, notice: t(:activated_user)) }        
        format.json { head :ok }

      else
        format.html { redirect_to(designates_allocations_url, alert: t(:activated_user_error)) }
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
          status_hash.select { |k,v| [allocation_status, Allocation_Activated, Allocation_Rejected].include?(k) }
        when Allocation_Activated
          status_hash.select { |k,v| [allocation_status, Allocation_Cancelled].include?(k) }
        when Allocation_Cancelled, Allocation_Rejected
          status_hash.select { |k,v| [allocation_status, Allocation_Activated].include?(k) }
      end
    end

end
