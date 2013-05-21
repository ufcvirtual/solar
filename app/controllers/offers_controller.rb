include ApplicationHelper
include OffersHelper

class OffersController < ApplicationController

  layout false, :except => [:index, :list]

  # Versão da Bianca
  def index
    @allocation_tags_ids = (params[:allocation_tags_ids].kind_of?(Array) ? params[:allocation_tags_ids] : params[:allocation_tags_ids].split(',').uniq.collect{|al| al.to_i})
    authorize! :index, Offer, :on => @allocation_tags_ids

    @offers = Offer.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids})
  end

  def list
    @offers = get_all_offers

    # ordenando os resultados
    @offers.sort! { |a,b| a.semester <=> b.semester } if params.include?(:search_semester)
    @offers.sort! { |a,b| a.curriculum_unit.name <=> b.curriculum_unit.name } if params.include?(:search_curriculum_unit)

    # Filtrando por período para o componente de edição
    if params.include?(:search_semester)
      params[:search_semester].strip!
      @offers = @offers.select { |offer| offer.semester.downcase.include?(params[:search_semester].downcase) }
      
      all_allocation_tag_ids = Array.new(@offers.count)
      @offers.each_with_index do |offer, i|
        respects_chained_filter = false
        offer[:allocation_tag_id] = [offer.allocation_tag.id]
        offer[:name] = offer.curriculum_unit.name
        params[:chained_filter] = [] unless params.include?(:chained_filter)
    
        # se offer.course.allocation_tag.id estiver nos parametros, ok
        respects_chained_filter = true if params[:chained_filter].include?(offer.course.allocation_tag.id.to_s)    
        
        #senão, se parametro estiver vazio, ok
        respects_chained_filter = true if params[:chained_filter].empty?
        
        @offers[i] = nil unless respects_chained_filter
        all_allocation_tag_ids[i] = offer[:allocation_tag_id] if respects_chained_filter
      end # offers each
      @offers = @offers.compact

      # Agrupando 
      reference_semester = ''
      reference_index = 0

      @offers.each_with_index do |offer,i|
        if (offer.semester == reference_semester)
          @offers[reference_index][:allocation_tag_id] += offer[:allocation_tag_id]
          @offers[reference_index].course = nil
          @offers[reference_index].name = nil
          @offers[reference_index].curriculum_unit = nil
          @offers[reference_index].start_date = nil
          @offers[reference_index].end_date = nil
          @offers[reference_index].id = nil
          @offers[i] = nil
        else
          reference_semester = offer.semester 
          reference_index = i
        end
      end

      @offers = @offers.compact
      all_allocation_tag_ids = all_allocation_tag_ids.compact.flatten

      all = {:semester => "..."+params[:search_semester]+"... (#{@offers.count})", :allocation_tag_id => all_allocation_tag_ids, :code => "*"}
      @offers.push(all)
    end # if search_semester
    
    # Filtrando por nome de unidade curricular
    if params.include?(:search_curriculum_unit)
      params[:search_curriculum_unit].strip!
      @offers = @offers.select { |offer| offer.curriculum_unit.name.downcase.include?(params[:search_curriculum_unit].downcase)}

      all_allocation_tag_ids = Array.new(@offers.count)
      @offers.each_with_index do |offer,i|
        respects_chained_filter = false
        offer[:allocation_tag_id] = [offer.allocation_tag.id.to_s]
        offer[:name] = offer.curriculum_unit.name
          
        params[:chained_filter] = [] unless params.include?(:chained_filter)
        
        #se offer.allocationTagId estiver em parametros, ok     
        respects_chained_filter = true if params[:chained_filter].include?(offer.allocation_tag.id.to_s)
          
        #offer.course.allocationTag.id estiver em parametros, ok 
        respects_chained_filter = true if params[:chained_filter].include?(offer.course.allocation_tag.id.to_s)
          
        #senão, se parametro estiver vazio, ok
        respects_chained_filter = true if params[:chained_filter].empty?
        
        @offers[i] = nil unless respects_chained_filter
        all_allocation_tag_ids[i] = offer[:allocation_tag_id] if respects_chained_filter
      end
      @offers = @offers.compact

      # Agrupando 
      reference_code = ''
      reference_index = 0
      @offers.each_with_index do |offer,i|
        if (offer.curriculum_unit.code == reference_code)
          @offers[reference_index][:allocation_tag_id] += offer[:allocation_tag_id]
          @offers[reference_index].course = nil
          @offers[reference_index].semester = nil
          @offers[reference_index].start_date = nil
          @offers[reference_index].end_date = nil
          @offers[reference_index].id = nil
          @offers[i] = nil
        else
          reference_code = offer.curriculum_unit.code
          reference_index = i
        end
      end
      @offers = @offers.compact
      all_allocation_tag_ids = all_allocation_tag_ids.compact.flatten

      all = {:name => '...' << params[:search_curriculum_unit] << "... (#{@offers.count})", :allocation_tag_id => all_allocation_tag_ids, :code => "*"}
      @offers.push(all)

    end # if search_curriculum_unit

    respond_to do |format|
      format.html
      format.json { render json: @offers }
      format.xml { render :xml => @offers }
    end

  end

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    authorize! :new, Offer, :on => @allocation_tags_ids
    @offer = Offer.new
  end

  def edit
    @offer = Offer.find(params[:id])
    authorize! :edit, Offer, on: [@offer.allocation_tag.id]
    @allocation_tags_ids = params[:allocation_tags_ids]
  end

  # Método que, a partir das ucs e cursos selecionados, cria ofertas para todas as combinações possíveis entre aqueles
  def create
    @allocation_tags_ids = (params[:allocation_tags_ids].kind_of?(Array) ? params[:allocation_tags_ids] : params[:allocation_tags_ids].split(',').uniq.collect{|al| al.to_i})
    # apenas para testar validação
    al_tag_test          = AllocationTag.find(@allocation_tags_ids.first.to_i)
    params[:offer][:course_id],params[:offer][:curriculum_unit_id] = (al_tag_test.course_id || al_tag_test.offer.course_id), (al_tag_test.curriculum_unit_id || al_tag_test.offer.curriculum_unit_id)
    params[:offer][:user_id] = current_user.id # para a alocação
    @offer = Offer.new(params[:offer])

    begin
      authorize! :create, Offer, :on => @allocation_tags_ids
      raise "erro" unless @offer.valid? # utilizado para validar os campos preenchidos e exibir erros quando necessário
      raise "schedule" unless (params[:enroll_end].nil? or @offer.end_date >= params[:enroll_end].to_date)

      params[:enroll_end] = nil unless params[:define_enroll_end]
      schedule    = Schedule.create!(start_date: params[:enroll_start], end_date: params[:enroll_end])
      schedule_id = schedule.nil? ? nil : schedule.id

      # Como os valores que vêm das alocations são de ofertas, é necessário pegar apenas aquelas com uc e curso diferentes
      allocation_tags_ids = @allocation_tags_ids.uniq {|a| 
        (AllocationTag.find(a).course_id || AllocationTag.find(a).offer.course_id) and (AllocationTag.find(a).curriculum_unit_id || AllocationTag.find(a).offer.curriculum_unit_id) 
      } || []

      allocation_tags_ids.each do |al_tag_id|
        allocation_tag = AllocationTag.find(al_tag_id)
        params[:offer][:course_id], params[:offer][:curriculum_unit_id] = (allocation_tag.course_id || allocation_tag.offer.course_id), (allocation_tag.curriculum_unit_id || allocation_tag.offer.curriculum_unit_id)
        params[:offer][:schedule_id] = schedule_id
        offer = Offer.create!(params[:offer])
        @allocation_tags_ids << offer.allocation_tag.id
      end

      redirect_to :action => :index, :allocation_tags_ids => @allocation_tags_ids

    rescue CanCan::AccessDenied
      @offers = @allocation_tags_ids.collect{|al| AllocationTag.find(al).offer}
      respond_to do |format|
        format.html { render :index, :status => 500 }
      end
    rescue Exception => error
      @offers = @allocation_tags_ids.collect{|al| AllocationTag.find(al).offer}
      respond_to do |format|
        @date_range_error = @offer.errors.full_messages.last unless @offer.errors[:start_date].blank? and @offer.errors[:end_date].blank?
        @schedule_error   = t(:schedule_error, :scope => [:offers]) if error.message == "schedule"
        @offer.errors.add(:semester, I18n.t(:existing_semester, :scope => [:offers])) if error.message == t(:semester, :scope => [:offers, :index]) + " " + t(:existing_semester, :scope => [:offers])
        format.html { render :new, :status => 200 }
      end
    end

  end

  def update
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @offer = Offer.find(params[:id])

    begin
      authorize! :update, Offer, :on => [@offer.allocation_tag.id] # verifica se tem acesso à oferta a ser editada

      params[:enroll_end] = nil unless params[:define_enroll_end]
      raise "schedule" unless (params[:enroll_end].nil? or @offer.end_date >= params[:enroll_end].to_date)

      schedule = Schedule.create!(start_date: params[:enroll_start], end_date: params[:enroll_end])

      @offer.update_attributes!(params[:offer])
      schedule.nil? ? @offer.update_attribute(:schedule_id, nil) : @offer.update_attribute(:schedule_id, schedule.id)
      redirect_to :action => :index, :allocation_tags_ids => @allocation_tags_ids

    rescue CanCan::AccessDenied
      @offers = @allocation_tags_ids.collect{|al| AllocationTag.find(al).offer}
      respond_to do |format|
        format.html { render :index, :status => 500 }
      end
    rescue Exception => error
      @offers = @allocation_tags_ids.collect{|al| AllocationTag.find(al).offer}
      respond_to do |format|
        @date_range_error = @offer.errors.full_messages.last unless @offer.errors[:start_date].blank? and @offer.errors[:end_date].blank?
        @schedule_error   = t(:schedule_error, :scope => [:offers]) if error.message == "schedule"
        format.html { render :edit, :status => 200 }
      end

    end
  end

  def destroy
    offer = Offer.find(params[:id])
    @allocation_tags_ids = params[:allocation_tags_ids]

    begin
      authorize! :destroy, Offer, :on => [offer.allocation_tag.id] # verifica se tem acesso à oferta a ser excluída
      allocation_tag_id = offer.allocation_tag.id.to_s
      raise "error" unless offer.destroy
      @allocation_tags_ids.delete(allocation_tag_id)
      flash[:notice] = t(:deleted_success, scope: :offers)
    rescue CanCan::AccessDenied
      flash[:alert] = t(:no_permission)
    rescue
      flash[:alert] = t(:not_possible_to_delete, scope: :offers)
    end
    redirect_to :action => :index, :allocation_tags_ids => @allocation_tags_ids
  end

  # Método que desabilita todos os grupos da oferta
  def deactivate_groups
    offer = Offer.find(params[:id])
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    @allocation_tags_ids = params[:allocation_tags_ids]

    begin 
      authorize! :deactivate_groups, Offer, :on => [offer.allocation_tag.id] # verifica se tem acesso à oferta a ter suas turmas desativadas
      offer.groups.each { |group| group.update_attributes!(:status => false) }

      flash[:notice] = t(:all_groups_deactivated, :scope => [:offers, :index])
    rescue CanCan::AccessDenied
      flash[:alert] = t(:no_permission)
    rescue
      flash[:alert] = t(:cant_deactivate, :scope => [:offers, :index])
    end
    redirect_to :action => :index, :allocation_tags_ids => @allocation_tags_ids
  end

  private

    def get_all_offers
      al                 = current_user.allocations.where(status: Allocation_Activated)
      my_direct_offers   = al.map(&:offer).compact
      offers_by_courses  = al.map(&:course).compact.map(&:offers).uniq
      offers_by_ucs      = al.map(&:curriculum_unit).compact.map(&:offers).flatten.uniq
      offers_by_groups   = al.map(&:group).compact.map(&:offer).uniq
      return [my_direct_offers + offers_by_courses + offers_by_ucs + offers_by_groups].flatten.compact.uniq
    end

end
