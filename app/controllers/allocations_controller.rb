include AllocationsHelper

class AllocationsController < ApplicationController

  authorize_resource :except => [:destroy, :designates, :create_designation, :activate, :deactivate]

  # GET /allocations/designates
  # GET /allocations/designates.json
  def designates
    
    # verifica permissao de acessar alocacao das allocation tags passadas
    authorize! :designates, Allocation, :on => [params[:allocation_tag_id].to_i]
    
    level        = (params[:permissions] != "all") ? "responsible" : nil
    level_search = level.nil? ? ("not(profiles.types & #{Profile_Type_Student})::boolean and not(profiles.types & #{Profile_Type_Basic})::boolean") : ("(profiles.types & #{Profile_Type_Class_Responsible})::boolean")
    
    @allocation_tags  = (params.include?('allocation_tag_id')) ? params[:allocation_tag_id] : 0
    
    @allocations = Allocation.find(:all,
      :joins => [:profile, :user], 
      :conditions => ["#{level_search} and allocation_tag_id IN (#{@allocation_tags}) "],
      :order => ["users.name", "profiles.name"]) 

    respond_to do |format|
      flash[:notice] = t(:allocated, :scope => [:allocations, :success]) if params.include?(:notice_allocated)
      flash[:alert]  = t(:not_allocated, :scope => [:allocations, :error]) if params.include?(:alert_allocated)
      format.html 
      format.json { render json: @allocations }
    end
  end

  # Método, chamado por ajax, para buscar usuários para alocação
  def search_users
    text          = URI.unescape(params[:data])
    @text_search  = text
    @allocation_tags = params[:allocation_tag_id]
    @users        = User.where("lower(name) ~ '#{text.downcase}'")

    render :layout => false
  end

  # GET /allocations/enrollments
  # GET /allocations/enrollments.json
  def index
    groups = current_user.groups.map(&:id)
    p      = params.select { |k, v| ['offer_id', 'group_id', 'status'].include?(k) }
    p['group_id'] = (params.include?('group_id') and groups.include?(params['group_id'].to_i)) ? [params['group_id']] : groups.flatten.compact.uniq

    @allocations  = Allocation.enrollments(p)

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
  
  # Usado na matrícula
  def create
    profile = student_profile
    status  = Allocation_Pending

    ok      = allocate(params[:allocation_tag_id], params[:user_id], profile, status, params[:id])
    message = ok ? ['notice', 'success'] : ['alert', 'error']

    respond_to do |format|
      format.html { redirect_to(enrollments_url, message[0].to_sym => t(:enrollm_request, :scope => [:allocations, message[1].to_sym])) }
    end
  end

  # Usado na alocacao de usuarios
  def create_designation

    # verifica permissao de alocacao nas allocation tags passadas
    authorize! :create_designation, Allocation, :on => [params[:allocation_tag_id].to_i] 

    profile = (params.include?(:profile)) ? params[:profile] : student_profile
    status  = (params.include?(:status)) ? params[:status] : Allocation_Pending

    ok      = allocate(params[:allocation_tag_id], params[:user_id], profile, status)
    message = ok ? ['notice', 'success'] : ['alert', 'error']

    respond_to do |format|
      format.html { redirect_to(designates_allocations_path(:allocation_tag_id => params[:allocation_tag_id]), message[0].to_sym => t(:enrollm_request, :scope => [:allocations, message[1].to_sym])) }
      format.json { render json: {:success => ok } }
    end
  end

  # PUT /allocations/1
  # PUT /allocations/1.json
  def update
    # authorize! :update, Allocation #.find(params[:id]) [authorize pelo authorize_resources]

    @allocation       = Allocation.find(params[:id])
    allocation_tag_id = (params.include?(:allocation) and params[:allocation].include?(:group_id)) ? Group.find(params[:allocation][:group_id]).allocation_tag.id : nil
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
      error     = true
      msg_error = t(:student_already_in_group, :scope => [:allocations, :error])
    rescue Exception
      error     = true
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
        @allocation.update_attributes!(:status => Allocation_Cancelled)
        message = t(:enrollm_cancelled_message)
      end
    rescue Exception => e
      message = t(:enrollm_not_cancelled_message)
      error   = true
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

    @allocation       = Allocation.find(params[:id])
    @text_search      = params[:text_search]
    allocation_tag_id = @allocation.allocation_tag_id

    # verifica permissao de desativar alocacao na allocation tag passada
    authorize! :deactivate, Allocation, :on => [allocation_tag_id.to_i]

    respond_to do |format|
      if @allocation.update_attribute(:status, Allocation_Cancelled)
        flash[:notice] = t(:deactivated, :scope => [:allocations, :success])
        format.html { redirect_to :action => :designates, :allocation_tag_id => allocation_tag_id }
        format.json { head :ok }
      else
        flash[:alert] = t(:not_deactivated, :scope => [:allocations, :error])
        format.html { redirect_to :action => :designates, :allocation_tag_id => allocation_tag_id }
        format.json { head :error }
      end
    end
  end

  def activate
    @allocation       = Allocation.find(params[:id])
    allocation_tag_id = @allocation.allocation_tag_id

    # verifica permissao de ativar alocacao na allocation tag passada
    authorize! :deactivate, Allocation, :on => [allocation_tag_id.to_i]

    respond_to do |format|
      if @allocation.update_attribute(:status, Allocation_Activated)
        flash[:notice] = t(:activated, :scope => [:allocations, :success])
        format.html { redirect_to :action => :designates, :allocation_tag_id => allocation_tag_id }
        format.json { head :ok }
      else
        flash[:alert] = t(:not_activated, :scope => [:allocations, :error])
        format.html { redirect_to :action => :designates, :allocation_tag_id => allocation_tag_id }
        format.json { head :error }
      end
    end
  end  

  def reactivate
    @allocation = Allocation.find(params[:id])
    respond_to do |format|
      if @allocation.update_attribute(:status, Allocation_Pending_Reactivate)       
        format.html { redirect_to(enrollments_url, notice: t(:enrollm_request, :scope => [:allocations, :success])) }        
        format.json { head :ok }
      else
        format.html { redirect_to(enrollments_url, alert: t(:enrollm_request, :scope => [:allocations, :error])) }        
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

    def allocate(allocation_tag_id, user_id, profile, status, id = nil)
      total, corrects = 0, 0
      if params.include?(:allocation_tag_id) and params.include?(:user_id) and (profile != '')
        unless params[:id].nil? # se alocação já existe (id não será nulo), então está desativada e deve ser reativada
          allocation        = Allocation.find(params[:id])
          allocation.status = Allocation_Pending_Reactivate
          total    = 1
          corrects = 1 if allocation.save
        else # se alocação está sendo realizada agora, deve ser criada
          allocations = params[:allocation_tag_id].split(',')
          total       = allocations.count()
          allocations.each do |id|
            allocation = Allocation.new({
              :user_id => params[:user_id],
              :allocation_tag_id => id,
              :profile_id => profile,
              :status => status
            })
            corrects = corrects + 1 if allocation.save
          end # allocations.each
        end # unless params[:id].nil?
      end
      return (corrects == total)
    end

end
