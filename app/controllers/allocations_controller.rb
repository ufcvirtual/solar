class AllocationsController < ApplicationController

  load_and_authorize_resource

  # todas as matriculas da alocation_tag selecionada
  def index
    
  end

  # mostra alocacao de aluno
  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  # aloca aluno
  def new
    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  # altera turma da alocacao
  def edit

  end

  # aceita matricula (alocacao)
  def acept
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Activated

    message = ''
    if @allocation.save
      message = t(:enrollm_acepted_message)
    end

    respond_to do |format|
      format.html { redirect_to(index, :notice => message) }
      format.xml  { head :ok }
    end
  end

  # rejeita matricula (alocacao)
  def reject
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Rejected

    message = ''
    if @allocation.save
      message = t(:enrollm_rejected_message)
    end

    respond_to do |format|
      format.html { redirect_to(index, :notice => message) }
      format.xml  { head :ok }
    end
  end

  def update
    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  # remove matricula (alocacao)
  def destroy
    @allocation.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  # cancela matricula (alocacao)
  def cancel
    @allocation = Allocation.find(params[:id])
    @allocation.status = Allocation_Cancelled

    message = ''
    if @allocation.save
      message = t(:enrollm_cancelled_message)
    end

    respond_to do |format|
      format.html { redirect_to(offers_showoffersbyuser_url, :notice => message) }
      format.xml  { head :ok }
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

  # cancela pedido de matricula (alocacao)
  def cancel_request
    @allocation = Allocation.find(params[:id])
    status = @allocation.status
    message = ''

    # se cancela 1o pedido de matricula (nao havia alocacao), remove pedido
    if status == Allocation_Pending

      if @allocation.destroy
         message = t(:enrollm_request_cancel_message)
      end

    else
      
      # se havia status cancelado anterior (havia alocacao), apenas cancela pedido
      if status == Allocation_Pending_Reactivate
        @allocation.status = Allocation_Cancelled
        if @allocation.save
          message = t(:enrollm_request_cancel_message)
        end
      end

    end

    respond_to do |format|
      format.html { redirect_to(offers_showoffersbyuser_url, :notice => message) }
      format.xml  { head :ok }
    end
  end

end
