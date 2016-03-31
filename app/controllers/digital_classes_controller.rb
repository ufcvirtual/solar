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

	private
	def digital_class_params
      params.require(:digital_class).permit(:name, :description)
    end
end
