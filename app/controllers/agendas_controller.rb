class AgendasController < ApplicationController
  before_filter :prepare_for_group_selection, only: :list

  layout false, only: [:calendar, :dropdown_content]

  def index
     # se não estiver em uma uc específica, recupera as allocations tags ativadas do usuário
    @allocation_tags = (active_tab[:url][:allocation_tag_id].nil?) ? current_user.activated_allocation_tag_ids : AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
    @link            = not(params[:list_all_schedule].nil?) # apresentacao dos links de todas as schedules
    @schedule        = Agenda.events(@allocation_tags, true, Date.parse(params[:date])) 
    render layout: false
  end

  def list
    @allocation_tags_ids = active_tab[:url][:allocation_tag_id]
    # raise "#{@allocation_tags_ids}"
    render action: :calendar
  end

  # calendário de eventos
  def calendar
    @allocation_tags_ids = (active_tab[:url].include?(:allocation_tag_id) ? [active_tab[:url][:allocation_tag_id]] : params[:allocation_tags_ids].split(" ")).flatten

    authorize! :calendar, Agenda, on: @allocation_tags_ids
    @access_forms = Event.descendants.collect{ |model| model.to_s.tableize.singularize if model.constants.include?("#{params[:selected].try(:upcase)}_PERMISSION".to_sym) }.compact.join(",")
  end

  # eventos para exibição no calendário
  def events
    @allocation_tags_ids = (active_tab[:url].include?(:allocation_tag_id) ? [active_tab[:url][:allocation_tag_id]] : params[:allocation_tags_ids].split(" ")).flatten
    authorize! :calendar, Agenda, on: @allocation_tags_ids

    events = (params.include?("list") ? 
      Event.descendants.map{ |event| event.scoped.after(Date.current, @allocation_tags_ids) }.uniq : 
      Event.descendants.map{ |event| event.scoped.between(params['start'], params['end'], @allocation_tags_ids) }.uniq )
    @events = [events].flatten.map(&:schedule_json).uniq

    render json: @events
  end

  def dropdown_content
    @model_name = params[:type].constantize
    @event = @model_name.find(params[:id])
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
  end

end
