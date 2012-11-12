class DiscussionsController < ApplicationController

  include EditionHelper

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
    @allocation_tags_ids = params[:allocation_tags_ids]

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    # raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)

    @discussion = Discussion.new
    render :layout => false
  end

  def create
    @discussion           = Discussion.new(params[:discussion])
    @schedule             = Schedule.new(:start_date => params["start_date"], :end_date => params["end_date"])
    @offer_id, @group_id  = params[:offer_id], params[:group_id]
    @allocation_tags_ids  = params[:allocation_tags_ids] # ids das allocations_tags de acordo com os dados passados
    offer                 = Offer.find(@offer_id)
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    # raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)

    begin 

      # período escolhido deve estar dentro do período da oferta
      raise "date_range_error" if @schedule.valid? and params["start_date"].to_date < offer.start or params["end_date"].to_date > offer.end

      ActiveRecord::Base.transaction do
        @allocation_tags_ids.split(" ").each do |allocation_tag_id|
          schedule   = Schedule.create!(:start_date => params["start_date"], :end_date => params["end_date"])
          discussion = Discussion.create!(:name => @discussion.name, :description => @discussion.description, :schedule_id => schedule.id, :allocation_tag_id => allocation_tag_id.to_i)
        end
      end
      @discussions = Discussion.all_by_allocation_tags(@allocation_tags_ids)

      respond_to do |format|
        format.html {render :list, :layout => false}
      end

    rescue Exception => error

      if error.message == "date_range_error"
        @schedule_error = t(:offer_period, :scope => [:discussion, :errors], :start => l(offer.start, :formats => :default), :end => l(offer.end, :formats => :default))
      elsif @discussion.valid? # se dados do fórum é válido e execução deu erro, o problema está na validação de nome único ou no período do schedule
        if @schedule.valid? # se o período do schedule é válido e execução deu erro, o problema está na validação de nome único 
          @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors]))
        end
      end

      @schedule_error = @schedule.errors.full_messages[0] unless @schedule.valid?

      respond_to do |format|
        format.html { render :new, :layout => false}
      end

    end # begin/rescue
  end

  def list
    @offer_id, @group_id = params[:offer_id], params[:group_id]
    @allocation_tags_ids = params[:allocation_tags_ids]

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    # raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)
    
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)
    @discussions          = Discussion.all_by_allocation_tags(@allocation_tags_ids)
    # @responsible_or_student = Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id) # verifica se usuário é responsável ou estudante para a oferta e turma

    render :layout => false
  end

  def edit
    @offer_id, @group_id = params[:offer_id], params[:group_id]
    @allocation_tags_ids = params[:allocation_tags_ids]
    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    # raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id)
    render :layout => false
  end

  def update
    schedule              = @discussion.schedule
    @offer_id, @group_id  = params[:offer_id], params[:group_id]
    @allocation_tags_ids  = params[:allocation_tags_ids]
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)
    offer                 = Offer.find(@offer_id)
    @discussions          = Discussion.all_by_allocation_tags(@allocation_tags_ids)

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    # raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, params[:offer_id], params[:group_id])
    unless @discussion.closed?
      
      begin
        
        schedule.update_attributes!(:start_date => params["start_date"], :end_date => params["end_date"])
        raise "date_range_error" if params["start_date"].to_date < offer.start or params["end_date"].to_date > offer.end
        @discussion.update_attributes!(params[:discussion])
        @discussions = Discussion.all_by_allocation_tags(@allocation_tags_ids)
        respond_to do |format|
          format.html {render :list, :layout => false}
        end

      rescue Exception => error

        if error.message == "date_range_error"
          @schedule_error = t(:offer_period, :scope => [:discussion, :errors], :start => l(offer.start, :formats => :default), :end => l(offer.end, :formats => :default))
        elsif @discussion.valid? # se dados do fórum é válido e execução deu erro, o problema está na validação de nome único ou no período do schedule
          if schedule.valid? # se o período do schedule é válido e execução deu erro, o problema está na validação de nome único 
            @discussion.errors.add(:name, t(:existing_name, :scope => [:discussion, :errors]))
          end
        end
        @schedule_error = schedule.errors.full_messages[0] unless schedule.valid?

        respond_to do |format|
          format.html { render :edit, :layout => false}
        end
      end

    else  
      @access_denied = true
      respond_to do |format|
        format.html { render :list, :layout => false }
      end
    end

  end

  def destroy
    @offer_id, @group_id  = params[:offer_id], params[:group_id]
    @allocation_tags_ids  = params[:allocation_tags_ids]
    @group_and_offer_info = group_and_offer_info(@group_id, @offer_id)

    # verifica se usuário, além de ter perfil de editor (authorize), é responsável ou estudante para a oferta e turma
    # raise CanCan::AccessDenied unless Profile.is_responsible_or_student?(current_user.id, @offer_id, @group_id) 

    schedule = @discussion.schedule
    if @discussion.destroy
      schedule.destroy
      
      @discussions = Discussion.all_by_allocation_tags(@allocation_tags_ids)
      render :list, :layout => false
    else
      @error_deletion = @discussion.errors.full_messages[0]
      @discussions    = Discussion.all_by_allocation_tags(@allocation_tags_ids)
      respond_to do |format|
        format.html{render :list, :layout => false}
      end
    end
  end

end
