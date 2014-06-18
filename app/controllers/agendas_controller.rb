class AgendasController < ApplicationController
  before_filter :prepare_for_group_selection, only: :list

  layout false, only: [:calendar, :dropdown_content]

  def index
     # se não estiver em uma uc específica, recupera as allocations tags ativadas do usuário
    @allocation_tags = (active_tab[:url][:allocation_tag_id].nil?) ? current_user.activated_allocation_tag_ids(true, true) : AllocationTag.find(active_tab[:url][:allocation_tag_id]).related.uniq
    @link            = not(params[:list_all_schedule].nil?) # apresentacao dos links de todas as schedules
    @schedule        = Agenda.events(@allocation_tags, true, Date.parse(params[:date])) 
    render layout: false
  end

  def list
    @allocation_tags_ids = (active_tab[:url].include?(:allocation_tag_id) ?  AllocationTag.find(active_tab[:url][:allocation_tag_id]).related.flatten : params[:allocation_tags_ids])
    @allocation_tags_ids = current_user.activated_allocation_tag_ids(true, true) if @allocation_tags_ids.nil?
    @allocation_tags_ids = @allocation_tags_ids.join(" ")

    authorize! :calendar, Agenda, {on: @allocation_tags_ids, read: true}
    render action: :calendar
  end

  # calendário de eventos
  def calendar
    @allocation_tags_ids = (active_tab[:url].include?(:allocation_tag_id) ? AllocationTag.find(active_tab[:url][:allocation_tag_id]).related.flatten.join(" ") : params[:allocation_tags_ids])

    authorize! :calendar, Agenda, {on: @allocation_tags_ids, read: true}
    @access_forms = Event.descendants.collect{ |model| model.to_s.tableize.singularize if model.constants.include?("#{params[:selected].try(:upcase)}_PERMISSION".to_sym) }.compact.join(",")
  end

  # eventos para exibição no calendário
  def events
    @allocation_tags_ids = (active_tab[:url].include?(:allocation_tag_id) ? AllocationTag.find(active_tab[:url][:allocation_tag_id]).map(&:related).flatten : params[:allocation_tags_ids].split(" ").flatten).uniq
    authorize! :calendar, Agenda, {on: @allocation_tags_ids, read: true}

    events = (params.include?("list") ? 
      Event.descendants.map{ |event| event.scoped.after(Date.current, @allocation_tags_ids) }.uniq : 
      Event.descendants.map{ |event| event.scoped.between(params['start'], params['end'], @allocation_tags_ids) }.uniq )
    @events = [events].flatten.map(&:schedule_json).uniq

    @allocation_tags_ids = @allocation_tags_ids.join(" ")
    render json: @events
  end

  def dropdown_content
    @model_name   = params[:type].constantize
    @event        = @model_name.find(params[:id])
    @allocation_tags_ids = params[:allocation_tags_ids]
    @groups_codes = @event.groups.map(&:code)
  end

end
