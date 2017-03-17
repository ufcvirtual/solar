class ChatRoomsController < ApplicationController

  include SysLog::Actions

  layout false, except: :list

  before_filter :prepare_for_group_selection, only: :list

  before_filter :get_groups_by_allocation_tags, only: [:new, :create] do |controller|
    @allocations = @groups.map(&:students_allocations).flatten.uniq
  end

  before_filter only: [:edit, :update, :show] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@chat_room = ChatRoom.find(params[:id]))
    @allocations = @groups.map(&:students_allocations).flatten.uniq
  end

  def list
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    authorize! :list, ChatRoom, on: [@allocation_tag_id]
    @user = current_user
    @can_evaluate = can? :evaluate, ChatRoom, { on: @allocation_tag_id }

    ats = AllocationTag.find(@allocation_tag_id).related

    permited_profiles = current_user.profiles_with_access_on('list', 'chat_rooms', ats, true)
    @alloc = current_user.allocations.where(profile_id: permited_profiles, allocation_tag_id: ats, status: Allocation_Activated).first.id
    @responsible = ChatRoom.responsible?(@allocation_tag_id, current_user.id)

    @is_student = @user.is_student?([@allocation_tag_id])

    @my_chats = Score.list_tool(current_user.id, @allocation_tag_id, 'chat_rooms', false, false, true)
    @other_chats = Score.list_tool(current_user.id, @allocation_tag_id, 'chat_rooms', false, false, true, true) unless @responsible
  end

  def index
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :index, ChatRoom, on: @allocation_tags_ids.split(' ').flatten

    @chat_rooms = ChatRoom.to_list_by_ats(@allocation_tags_ids.split(' ').flatten)
  end

  def show
    authorize! :show, ChatRoom, on: @allocation_tags_ids
  end

  def new
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(' ').flatten

    @chat_room = ChatRoom.new
    @chat_room.build_schedule(start_date: Date.today, end_date: Date.today)

    @academic_allocations = @chat_room.academic_allocations.build @allocation_tags_ids.map { |at| { allocation_tag_id: at } }
    @academic_allocations.first.chat_participants.build # escolha de participantes apenas para uma turma
  end

  def edit
    authorize! :update, ChatRoom, on: @allocation_tags_ids
  end

  def create
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @chat_room = ChatRoom.new chat_room_params
    @chat_room.allocation_tag_ids_associations = @allocation_tags_ids.split(' ').flatten

    if @chat_room.save
      render_notification_success_json('created')
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def update
    authorize! :update, ChatRoom, on: @chat_room.academic_allocations.pluck(:allocation_tag_id)

    if @chat_room.update_attributes(chat_room_params)
      render_notification_success_json('updated')
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @chat_rooms = ChatRoom.where(id: params[:id].split(','))
    authorize! :destroy, ChatRoom, on: @chat_rooms.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    if @chat_rooms.map(&:can_remove_groups?).include?(false)
      render json: {success: false, alert: t('chat_rooms.error.chat_has_messages')}, status: :unprocessable_entity
    else
      evaluative = @chat_rooms.map(&:verify_evaluatives).include?(true)
      ChatRoom.transaction do
        @chat_rooms.destroy_all
      end

      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t(:deleted, scope: [:chat_rooms, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    end
  rescue => error
    render_json_error(error, 'chat_rooms.error')
  end

  ## GET /chat_roms/1/messages/user/1
  def user_messages
    if user_session[:blocking_content]
      render text: t('exams.restrict')
    else
      @user = User.find(params[:user_id])
      @chat_room = ChatRoom.find(params[:id])

      allocation_tag_id = active_tab[:url][:allocation_tag_id]

      authorize! :show, ChatRoom, on: [allocation_tag_id]
      raise CanCan::AccessDenied if !(ChatRoom.responsible_or_observer?(allocation_tag_id, current_user.id)) && !(@researcher) && current_user.id != @user.id

      @academic_allocation = @chat_room.academic_allocations.where(allocation_tag_id: allocation_tag_id).first
      can_evaluate = can? :evaluate, ChatRoom, {on: allocation_tag_id}
      @evaluative = can_evaluate && @academic_allocation.evaluative
      @frequency = can_evaluate && @academic_allocation.frequency

      @messages = @chat_room.get_messages(allocation_tag_id, (params.include?(:user_id) ? {user_id: params[:user_id]} : {}))
            
      @acu = AcademicAllocationUser.find_one(@academic_allocation.id, params[:user_id],nil, false, can_evaluate)

      respond_to do |format|
        format.html { render layout: false }
        format.json { render json: @messages }
      end
    end  
  end  

  def messages
    if user_session[:blocking_content]
      render text: t('exams.restrict')
    else
      @chat_room, allocation_tag_id = ChatRoom.find(params[:id]), active_tab[:url][:allocation_tag_id]
      authorize! :show, ChatRoom, on: [allocation_tag_id]
      @academic_allocation = AcademicAllocation.where(academic_tool_id: @chat_room.id, academic_tool_type: 'ChatRoom', allocation_tag_id: allocation_tag_id).first
      all_participants = @chat_room.participants.where(academic_allocations: { allocation_tag_id: allocation_tag_id })
      @researcher = current_user.is_researcher?(AllocationTag.find(allocation_tag_id).related)
      responsible = ChatRoom.responsible_or_observer?(allocation_tag_id, current_user.id)

      raise CanCan::AccessDenied if (all_participants.any? && all_participants.joins(:user).where(users: { id: current_user }).empty?) && !responsible && !(@researcher)

      can_evaluate = can? :evaluate, ChatRoom, {on: allocation_tag_id}
      @evaluative = (can_evaluate && @academic_allocation.evaluative)
      @frequency = (can_evaluate && @academic_allocation.frequency)

      @messages = @chat_room.get_messages(allocation_tag_id, (params.include?(:user_id) ? {user_id: params[:user_id]} : {}))
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def access
    if user_session[:blocking_content]
      render text: t('exams.restrict')
    else
      @chat_room, allocation_tag_id = ChatRoom.find(params[:id]), active_tab[:url][:allocation_tag_id]
      authorize! :show, ChatRoom, on: [allocation_tag_id]
      
      academic_allocation_id = params[:academic_allocation_id]
      allocation_id = params[:allocation_id]

      chat_rooms = ChatRoom.find(params[:id])
      url = chat_rooms.url(allocation_id, academic_allocation_id)
      URI.parse(url).path
      redirect_to url
    end  
  end

  def participants
    authorize! :show, ChatRoom, on: [at_id = active_tab[:url][:allocation_tag_id]]

    @chat = ChatRoom.find(params[:id])
    @participants = @chat.users.where('academic_allocations.allocation_tag_id = ?', at_id)

    render layout: false
  end

  private

    def chat_room_params
      params.require(:chat_room).permit(:title, :description, :chat_type, :start_hour, :end_hour,
        schedule_attributes: [:id, :start_date, :end_date],
        academic_allocations_attributes: [:id, :allocation_tag_id, chat_participants_attributes: [:id, :allocation_id, :_destroy]])
    end

    def render_notification_success_json(method)
      render json: {success: true, notice: t(method, scope: 'chat_rooms.success')}
    end

end
