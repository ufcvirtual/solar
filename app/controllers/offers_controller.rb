include ApplicationHelper
include OffersHelper

class OffersController < ApplicationController

  layout false, :except => [:index, :list]

  # Versão da Bianca
  def index
    # não poderão vir com o valor 0 (indicando que "nenhum" foi selecionado, pois as ofertas dependem de ambos)
    @course_id, @curriculum_unit_id = (params[:course_id] || "all"), (params[:curriculum_unit_id] || "all") # a fim de testes: editor, atualmente, tem permissão para uc: 3 e curso: 2
    authorize! :index, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e cursos selecionados
    get_offers(@curriculum_unit_id, @course_id)
  end

  def list
    # @course_id, @curriculum_unit_id = (params[:course_id] || "all"), (params[:curriculum_unit_id] || "all") # a fim de testes: editor, atualmente, tem permissão para uc: 3 e curso: 2
    # authorize! :index, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e cursos selecionados
    # get_offers(@curriculum_unit_id, @course_id)
  
    @offers = get_all_offers

    # if params.include?(:course)
    #   @offers = @offers.select { |offer| offer.course_id == params[:course].to_i }
    # end

    # if params.include?(:period)
    #   @offers = @offers.select { |offer| offer.semester.downcase.include?(params[:period].downcase) }
    # end

    # ordenando os resultados
    @offers.sort! { |a,b| a.semester <=> b.semester } if params[:search_semester].present?
    @offers.sort! { |a,b| a.curriculum_unit.name <=> b.curriculum_unit.name } if params[:search_curriculum_unit].present?

    # Filtrando por período para o componente de edição
    if params[:search_semester].present?
      params[:search_semester].strip!
      @offers = @offers.select { |offer| offer.semester.downcase.include?(params[:search_semester].downcase) }
      
      all_allocation_tag_ids = Array.new(@offers.count)
      @offers.each_with_index do |offer,i|
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

      all = {:semester => "..."+params[:search_semester]+"... (#{@offers.count})", :allocation_tag_id => all_allocation_tag_ids}
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

      all = {:name => '...' << params[:search_curriculum_unit] << "... (#{@offers.count})", :allocation_tag_id => all_allocation_tag_ids}
      @offers.push(all)

    end # if search_curriculum_unit

    respond_to do |format|
      format.html
      format.json { render json: @offers }
      format.xml { render :xml => @offers }
    end

  end

  def new
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    authorize! :new, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e curso selecionados
    @offer = Offer.new
  end

  def edit
    @offer = Offer.find(params[:id])
    authorize! :edit, Offer, :on => [@offer.allocation_tag.id]
  end

  # Método que, a partir das ucs e cursos selecionados, cria ofertas para todas as combinações possíveis entre aqueles
  def create
    params[:offer][:curriculum_unit_id], params[:offer][:course_id] = CurriculumUnit.first, Course.first # valores aleatórios utilizados apenas para testar a validade da oferta
    params[:offer][:user_id] = current_user.id # para a alocação
    @offer = Offer.new(params[:offer])

    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    get_curriculum_units_and_courses(@curriculum_unit_id, @course_id)

    begin
      authorize! :create, Offer, :on => get_allocations_tags(nil, @curriculum_unit_id, @course_id) # verifica se tem acesso aos uc e curso selecionados
      raise "erro" unless @offer.valid? # utilizado para validar os campos preenchidos e exibir erros quando necessário

      @courses.each do |course| # lista de cursos dependendo do que foi selecionado previamente 
        @curriculum_units.each do |curriculum_unit| # lista de ucs dependendo do que foi selecionado previamente 
          params[:offer][:curriculum_unit_id], params[:offer][:course_id] = curriculum_unit.id, course.id
          offer = Offer.create!(params[:offer]) # cria uma oferta para cada combinação de uc e curso
        end
      end

      respond_to do |format|
        get_offers(@curriculum_unit_id, @course_id)
        format.html { render :index, :status => 200 }
      end

    rescue CanCan::AccessDenied
      respond_to do |format|
        get_offers(@curriculum_unit_id, @course_id)
        format.html { render :index, :status => 500 }
      end
    rescue
      respond_to do |format|
        @date_range_error = @offer.errors.full_messages.last unless @offer.errors[:start_date].blank? and @offer.errors[:end_date].blank?
        format.html { render :new, :status => 200 }
      end
    end

  end

  def update
    @offer = Offer.find(params[:id])
    params[:offer][:curriculum_unit_id], params[:offer][:course_id] = @offer.curriculum_unit_id, @offer.course_id
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]

    begin
      authorize! :update, Offer, :on => [@offer.allocation_tag.id] # verifica se tem acesso à oferta a ser editada

      @offer.update_attributes!(params[:offer])
      respond_to do |format|
        get_offers(params[:curriculum_unit_id], params[:course_id])
        format.html { render :index, :status => 200 }
      end
    rescue CanCan::AccessDenied
      respond_to do |format|
        get_offers(@curriculum_unit_id, @course_id)
        format.html { render :index, :status => 500 }
      end
    rescue
      respond_to do |format|
        @date_range_error = @offer.errors.full_messages.last unless @offer.errors[:start_date].blank? and @offer.errors[:end_date].blank?
        format.html { render :edit, :status => 200 }
      end

    end
  end

  def destroy
    offer = Offer.find(params[:id])
    @course_id, @curriculum_unit_id = params[:course_id], params[:curriculum_unit_id]

    begin
      authorize! :destroy, Offer, :on => [offer.allocation_tag.id] # verifica se tem acesso à oferta a ser excluída
      raise "error" unless offer.destroy

      respond_to do |format|
        get_offers(@curriculum_unit_id, @course_id)
        format.html { render :index, :status => 200 }
      end
    rescue 
      get_offers(@curriculum_unit_id, @course_id)
      respond_to do |format|
        format.html { render :index, :status => 500 }
      end
    end

  end

  # Método que desabilita todos os grupos da oferta
  def deactivate_groups
    offer = Offer.find(params[:id])
    @curriculum_unit_id, @course_id = params[:curriculum_unit_id], params[:course_id]
    get_offers(@curriculum_unit_id, @course_id)

    begin 
      authorize! :deactivate_groups, Offer, :on => [offer.allocation_tag.id] # verifica se tem acesso à oferta a ter suas turmas desativadas
      offer.groups.each { |group| group.update_attributes!(:status => false) }
      respond_to do |format|
        format.html{ render :index, :status => 200 }
      end
    rescue
      respond_to do |format|
        format.html{ render :index, :status => 500 }
      end
    end
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
