class AgendasController < ApplicationController
  before_filter :prepare_for_group_selection, only: :list

  layout false, only: [:calendar]

  def index
     # se não estiver em uma uc específica, recupera as allocations tags ativadas do usuário
    @allocation_tags = (active_tab[:url][:allocation_tag_id].nil?) ? current_user.activated_allocation_tag_ids : AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
    @link            = not(params[:list_all_schedule].nil?) # apresentacao dos links de todas as schedules
    @schedule        = Agenda.events(@allocation_tags, true, Date.parse(params[:date])) 
    render layout: false
  end

  def list
    allocation_tags = active_tab[:url][:allocation_tag_id] || params[:allocation_tags_ids]
    @schedule       = Agenda.events(allocation_tags)
  end

  # calendário de eventos
  def calendar
    authorize! :calendar, Agenda, on: (active_tab[:url].include?(:allocation_tag_id) ? [active_tab[:url][:allocation_tag_id]] : params[:allocation_tags_ids].split(" "))
  end

  # eventos para exibição no calendário
  def events
    @allocation_tags_ids = (active_tab[:url].include?(:allocation_tag_id) ? [active_tab[:url][:allocation_tag_id]] : params[:allocation_tags_ids].split(" "))
    authorize! :calendar, Agenda, on: @allocation_tags_ids

    unless params.include?("list")
      @assignments = Assignment.scoped.between(params['start'], params['end'], @allocation_tags_ids).uniq
      @chats = ChatRoom.scoped.between(params['start'], params['end'], @allocation_tags_ids).uniq
      @discussions = Discussion.scoped.between(params['start'], params['end'], @allocation_tags_ids).uniq
      @schedules_events = ScheduleEvent.scoped.between(params['start'], params['end'], @allocation_tags_ids).uniq
    else
      @assignments = Assignment.scoped.after(Date.current, @allocation_tags_ids).uniq
      @chats = ChatRoom.scoped.after(Date.current, @allocation_tags_ids).uniq
      @discussions = Discussion.scoped.after(Date.current, @allocation_tags_ids).uniq
      @schedules_events = ScheduleEvent.scoped.after(Date.current, @allocation_tags_ids).uniq
    end

    @events = (@assignments + @chats + @discussions + @schedules_events).map(&:schedule_json)

    render json: @events
  end

  def dropdown_content
    model_name = params[:type].constantize
    render partial: "event_resume", locals: {event: model_name.find(params[:id]), model_name: model_name, allocation_tags_ids: params[:allocation_tags_ids].split(" ")}
  end

end
