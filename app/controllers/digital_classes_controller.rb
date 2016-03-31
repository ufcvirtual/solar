class DigitalClassesController < ApplicationController

	include SysLog::Actions

	before_filter :prepare_for_group_selection, only: :list
	before_filter :get_ac, only: :evaluate
	before_filter :get_groups_by_allocation_tags, only: [:new, :create]

	layout false, except: :index
	before_filter only: [:edit, :update, :show] do |controller|
		@allocation_tags_ids = params[:allocation_tags_ids]
		get_groups_by_tool(@digital_class = DigitalClass.find(params[:id]))
	end

	def list
		@allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
		authorize! :list, DigitalClass, on: @allocation_tags_ids
		# @digital_classes = DigitalClass.all#joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).uniq
		# rescue => error
		#    request.format = :json
		#    raise error.class
	end
	def new
		authorize! :new, DigitalClass, on: @allocation_tags_ids = params[:allocation_tags_ids]
		#@digital_class = DigitalClass.new
	end
	def create
	end

  def update_members_and_roles_page
		authorize! :update_members_and_roles_page, DigitalClass
		@types = ((!EDX.nil? && EDX['integrated']) ? CurriculumUnitType.all : CurriculumUnitType.where('id <> 7'))
	  rescue
		render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def update_members_and_roles
		raise 'unavailable' unless DigitalClass.available?

		allocation_tags = AllocationTag.get_by_params(params)
		authorize! :update_members_and_roles_page, DigitalClass, { on: allocation_tags[:allocation_tags].compact, accepts_general_profile: true }
		query = ['updated_at::date >= :initial_date']

		unless allocation_tags[:allocation_tags].compact.blank?
		  ats = RelatedTaggable.related_from_array_ats(allocation_tags[:allocation_tags].compact)
		  query << 'allocation_tag_id IN (:allocation_tags)' 
		end

		allocations = Allocation.where(query.join(' AND '), { initial_date: params[:initial_date], allocation_tags: ats })
		result = DigitalClass.update_multiple(allocations)
		raise 'error' if !result
		render json: { success: true, notice: t('digital_classes.success_message') }
	  rescue CanCan::AccessDenied
		render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
	  rescue => error
		render_json_error(error, 'digital_classes')
  end

  def index
  end

  private
	def digital_class_params
	  params.require(:digital_class).permit(:name, :description)
	end

end
