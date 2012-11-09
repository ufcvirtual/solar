class GroupsController < ApplicationController

  # load_and_authorize_resource


	#Webservice utilizado pelo Mobilis
	def index
		@groups = current_user.groups

		if params.include?(:curriculum_unit_id)
			ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
			@groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
		end

		respond_to do |format|
			format.html
			format.xml  { render :xml => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester} } }
			format.json  { render :json => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester} } }
		end
	end

	#Webservice utilizado pelo componente de publicação
	def list
		al                 = current_user.allocations.where(status: Allocation_Activated)
		my_direct_groups   = al.map(&:group).compact
		groups_by_offers   = al.map(&:offer).compact.map(&:groups).uniq
		groups_by_courses  = al.map(&:course).compact.map(&:groups).uniq
		groups_by_ucs      = al.map(&:curriculum_unit).compact.map(&:groups).uniq
		
		@groups            = [my_direct_groups + groups_by_offers + groups_by_courses + groups_by_ucs].flatten.compact.uniq

		if params.include?(:curriculum_unit_id)
			ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
			@groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
		end

		if params.include?(:search)
			@groups = @groups.select { |group| group.code.downcase.include?(params[:search].downcase) }

			all_allocation_tag_ids = Array.new(@groups.count)
			@groups.each_with_index do |group,i|
				respects_chained_filter = false

				group[:allocation_tag_id] = group.allocation_tag.id

		        params[:chained_filter] = [] unless params.include?(:chained_filter)

				# se group.offer.allocation_tag.id estiver nos parametros, ok
				respects_chained_filter = true if params[:chained_filter].include?(group.offer.allocation_tag.id.to_s)    
				
				# se group.course.allocation_tag.id estiver nos parametros, ok
				respects_chained_filter = true if params[:chained_filter].include?(group.course.allocation_tag.id.to_s)    

				#senão, se parametro estiver vazio, ok
				respects_chained_filter = true if params[:chained_filter].empty?
				
				all_allocation_tag_ids[i] = group[:allocation_tag_id] if respects_chained_filter

				@groups[i] = nil unless respects_chained_filter		
			end
			@groups = @groups.compact			
			all_allocation_tag_ids = all_allocation_tag_ids.compact

			optionAll = {:code => params[:search]+"...", :id =>nil , :allocation_tag_id => all_allocation_tag_ids, :name =>"*"}
			@groups << optionAll
			
		end

		respond_to do |format|
		  format.html
		  format.xml  { render xml: @groups}
		  format.json  { render json: @groups }
		  
		end
	end

	def new
		@group = Group.new

		## verificar o que carregar de dados => ainda nao pronto

		@offers = Offer.all
		@courses = Course.all
		@curriculum_units = CurriculumUnit.all

		render layout: false
	end

	def edit
		@group = Group.find(params[:id])

		## verificar o que carregar de dados => ainda nao pronto

		@edit = true
		@offers = [@group.offer]
		@curriculum_units = [@offers.first.curriculum_unit]
		@courses = Course.all

		render layout: false
	end

	def create
		params[:group][:user_id] = current_user.id
		@group = Group.new(params[:group])

		respond_to do |format|
			if @group.save
				format.html { redirect_to groups_url, notice: t(:successfully_created, :register => @group.code) }
			else
				format.html { render action: "new" }
			end
		end
	end

	def update
		@group = Group.find(params[:id])

		if @group.update_attributes(params[:group])
			redirect_to groups_url, notice: t(:successfully_updated, :register => @group.code)
		else
			redirect_to edit_group_url(@group), :alert => @group.errors
		end
	end

	def destroy
		begin
			@group = Group.find(params[:id])
			if @group.destroy
				redirect_to groups_url, :notice => t(:successfully_deleted, :register => @group.code_semester)
			else
				redirect_to groups_url, :alert => t(:cant_delete, :register => @group.code_semester)
			end
		rescue
			redirect_to groups_url, :alert => t(:cant_delete, :register => @group.code_semester)
		end
	end

end
