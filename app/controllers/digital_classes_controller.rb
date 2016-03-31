class DigitalClassesController < ApplicationController

  include SysLog::Actions

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

end
