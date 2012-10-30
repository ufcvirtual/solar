class DiscussionsController < ApplicationController

  authorize_resource :only => [:index, :new, :create, :list]
  load_and_authorize_resource :only => [:edit, :update, :destroy]

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
    @offer_id, @group_id = params[:offer_id], params[:group_id]

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)

    @discussion = Discussion.new
    render :layout => false
  end

  def create
    @discussion          = Discussion.new(params[:discussion])
    @schedule            = Schedule.new(:start_date => params["start_date"], :end_date => params["end_date"])
    @offer_id, @group_id = params["offer_id"], params["group_id"]
    allocations_tags_ids = AllocationTag.by_offer_and_group(@offer_id, @group_id) # ids das allocations_tags de acordo com os dados passados

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)

    begin 

      ActiveRecord::Base.transaction do
        allocations_tags_ids.each do |allocation_tag_id|
          schedule   = Schedule.create!(:start_date => params["start_date"], :end_date => params["end_date"])
          discussion = Discussion.create!(:name => @discussion.name, :description => @discussion.description, :schedule_id => schedule.id, :allocation_tag_id => allocation_tag_id.to_i)
        end
      end

      redirect_to list_discussions_url, :notice => t(:created, :scope => [:discussion, :success])

    rescue Exception => error

      if @discussion.valid? # se dados do fórum é válido e execução deu erro, o problema está na validação de nome único ou no período do schedule
        if @schedule.valid? # se o período do schedule é válido e execução deu erro, o problema está na validação de nome único 
          @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors]))
        else
          @schedule_error = @schedule.errors.full_messages[0]
        end
      end

      render :action => "new"

    end # begin/rescue
  end

  def list
    # @offer_id, @group_id = params["offer_id"], params["group_id"]
    @offer_id, @group_id = 3, "all" # temporário com a finalidade de testes. quando for definido o acesso à página, utilizar linha anterior adaptada.

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)
    
    if @group_id == "all"
      group_code = t(:all_groups, :scope => [:discussion])
    elsif @group_id != 0
      group_code  = Group.find(@group_id).code
    end

    allocations_tags_ids         = AllocationTag.by_offer_and_group(@offer_id, @group_id) # ids das allocations_tags de acordo com os dados passados
    @discussions                 = Discussion.all_by_allocation_tags(allocations_tags_ids)
    @group_code, @offer_semester = group_code, Offer.find(@offer_id).semester # utilizados para informar usuário na página
    @responsible_or_student      = Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id) # verifica se usuário é responsável ou estudante para a oferta e turma
  end

  def edit
    @offer_id, @group_id = params[:offer_id], params[:group_id]

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)
    
    render :layout => false
  end

  def update
    schedule = @discussion.schedule

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, params[:offer_id], params[:group_id])

    unless @discussion.closed?
      begin
        schedule.update_attributes!(:start_date => params["start_date"], :end_date => params["end_date"])
        @discussion.update_attributes!(params[:discussion])
        redirect_to list_discussions_url, :notice => t(:updated, :scope => [:discussion, :success])
      rescue Exception => error
        render :action => "edit"
      end
    else
      redirect_to list_discussions_url, :alert => t(:cant_edit, :scope => [:discussion, :errors])
    end

  end

  def destroy
    @offer_id, @group_id = params["offer_id"], params["group_id"]

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id) 

    schedule = @discussion.schedule
    if @discussion.destroy
      schedule.destroy
      redirect_to list_discussions_url, :notice => t(:deleted, :scope => [:discussion, :success])
    else
      redirect_to list_discussions_url, :alert => @discussion.errors.full_messages[0]
    end
  end

end
