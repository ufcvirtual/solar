class AgendasController < ApplicationController
  before_filter :prepare_for_group_selection, only: :list

  layout false, only: [:calendar, :dropdown_content, :index]

  before_filter except: :dropdown_content do |controller|
    @allocation_tags_ids = (
      active_tab[:url].include?(:allocation_tag_id) ? AllocationTag.find(active_tab[:url][:allocation_tag_id]).related : (
        params[:allocation_tags_ids].blank? ? current_user.activated_allocation_tag_ids(true, true) : params[:allocation_tags_ids].split(" ").flatten
      )
    ).uniq
  end

  after_filter only: [:list, :events] do |controller|
    @allocation_tags_ids = @allocation_tags_ids.join(" ") unless @allocation_tags_ids.nil?
  end

  def index
    @schedules = Agenda.events(@allocation_tags_ids, params[:date])
  end

  def list
    render action: :calendar
  end

  def calendar
    @access_forms = Event.descendants.collect{ |model| model.to_s.tableize.singularize if model.constants.include?("#{params[:selected].try(:upcase)}_PERMISSION".to_sym) }.compact.join(",")
  end

  def events
    authorize! :calendar, Agenda, {on: @allocation_tags_ids, read: true}
    render json: [Event.all_descendants(@allocation_tags_ids, current_user, params.include?("list"), params)].flatten.map(&:schedule_json).uniq
  end

  def dropdown_content
    @model_name = model_by_param_type(params[:type])
    @event      = @model_name.find(params[:id])
    @groups     = @event.groups
    @allocation_tags_ids = params[:allocation_tags_ids]
  end

  private

    def model_by_param_type(type)
      type.constantize if ['Assignment', 'Discussion', 'ChatRoom', 'ScheduleEvent', 'Lesson'].include?(type)
    end

end
