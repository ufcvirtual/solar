include ApplicationHelper

class OffersController < ApplicationController

  before_filter :get_values, :only => [:new, :edit]

  def index
    # authorize! :index, Offer

    al                = current_user.allocations.where(status: Allocation_Activated)
    my_direct_offers  = al.map(&:offer).compact
    offers_by_courses  = al.map(&:course).compact.map(&:offer).uniq
    offers_by_ucs      = al.map(&:curriculum_unit).compact.map(&:offers).flatten.uniq
    offers_by_groups   = al.map(&:group).compact.map(&:offer).uniq
    @offers           = [my_direct_offers + offers_by_courses + offers_by_ucs + offers_by_groups].flatten.compact.uniq

    if params.include?(:course)
      @offers = @offers.select { |offer| offer.course_id == params[:course].to_i }
    end

    if params.include?(:period)
      @offers = @offers.select { |offer| offer.semester.downcase.include?(params[:period].downcase) }
    end

    # Filtrando por período para o componente de edição
    if params.include?(:search_semester)
		
      @offers = @offers.select { |offer| offer.semester.downcase.include?(params[:search_semester].downcase) }
      
      all_allocation_tag_ids = Array.new(@offers.count)
	  @offers.each_with_index do |offer,i|
        respects_chained_filter = false
        offer[:allocation_tag_id] = offer.allocation_tag.id
        offer[:name] = offer.curriculum_unit.name
        
        params[:chained_filter] = [] unless params.include?(:chained_filter)
		
		# se offer.course.allocation_tag.id estiver nos parametros, ok
		respects_chained_filter = true if params[:chained_filter].include?(offer.course.allocation_tag.id.to_s)    
		
		#senão, se parametro estiver vazio, ok
		respects_chained_filter = true if params[:chained_filter].empty?
		
		@offers[i] = nil unless respects_chained_filter
		all_allocation_tag_ids[i] = offer[:allocation_tag_id] if respects_chained_filter
	  end
	  @offers = @offers.compact
	  all_allocation_tag_ids = all_allocation_tag_ids.compact

      all = {:semester => params[:search_semester]+"...", :id => all_allocation_tag_ids}
      @offers.push(all)
    end
    
    # Filtrando por nome de unidade curricular
    if params.include?(:search_curriculum_unit)
      @offers = @offers.select { |offer| offer.curriculum_unit.name.downcase.include?(params[:search_curriculum_unit].downcase)}

	  all_allocation_tag_ids = Array.new(@offers.count)
	  @offers.each_with_index do |offer,i|
	  	respects_chained_filter = false
        offer[:allocation_tag_id] = offer.allocation_tag.id.to_s
        offer[:name] = offer.curriculum_unit.name
        
		params[:chained_filter] = [] unless params.include?(:chained_filter)
		
		#se offer.allocationTagId estiver em parametros, ok 		
		respects_chained_filter = true if params[:chained_filter].include?(offer[:allocation_tag_id])
			
		#offer.course.allocationTag.id estiver em parametros, ok 
		respects_chained_filter = true if params[:chained_filter].include?(offer.course.allocation_tag.id.to_s)
			
		#senão, se parametro estiver vazio, ok
		respects_chained_filter = true if params[:chained_filter].empty?
		
		@offers[i] = nil unless respects_chained_filter
		all_allocation_tag_ids[i] = offer[:allocation_tag_id] if respects_chained_filter
	  end
	  @offers = @offers.compact
	  all_allocation_tag_ids = all_allocation_tag_ids.compact

      all = {:name => params[:search_curriculum_unit]+"...", :id => all_allocation_tag_ids}
      @offers.push(all)
    end
    

    respond_to do |format|
      format.html
      format.json { render json: @offers }
      format.xml { render :xml => @offers }
    end
  end

  def new
    @offer = Offer.new
    @start_date = l Date.today
    @end_date = l Date.today
  end

  def edit
    @offer = Offer.find(params[:id])
    @start_date = l @offer.start
    @end_date = l @offer.end
  end

  def create
    @offer = Offer.new(
      :course_id => params[:course_id],
      :curriculum_unit_id => params[:curriculum_unit_id],
      :semester => params[:offer][:semester],
      :start => params[:offer][:start],
      :end => params[:offer][:end]
    )

    respond_to do |format|
      if @offer.save
        format.html { redirect_to(offers_url) }
        format.xml  { render :xml => @offer }
      else
        format.html
        format.xml
      end
    end
  end

  def update
    offer = Offer.find(params[:id])

    respond_to do |format|
      if offer.update_attributes(params[:offer])
        format.html { redirect_to(offers_url) }
        format.xml  { render :xml => @offer }
      else
        format.html
        format.xml
      end
    end
  end

  # GET /offers/1
  # GET /offers/1.json
  def show
    @offer = Offer.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @offer }
    end
  end

  # DELETE /offers/1
  # DELETE /offers/1.json
  def destroy
    offer = Offer.find(params[:id])
    offer.destroy

    respond_to do |format|
      format.html { redirect_to(offers_url) }
      format.xml  { head :ok }
    end
  end

  private

  def get_values
    @courses = Course.find(:all)
    @curriculum_units = CurriculumUnit.find(:all)
  end

end
