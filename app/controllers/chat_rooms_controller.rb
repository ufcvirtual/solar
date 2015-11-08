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

    permited_profiles = current_user.profiles_with_access_on('list', 'chat_rooms', AllocationTag.find(@allocation_tag_id).related, true)
    @alloc = current_user.allocations.where(profile_id: permited_profiles).first.id
    @responsible = ChatRoom.responsible?(@allocation_tag_id, current_user.id)

    chats = ChatRoom.chats_user(current_user.id, @allocation_tag_id)
    @my_chats, @other_chats = chats[:my], chats[:others]
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

    if @chat_rooms.map(&:can_destroy?).include?(false)
      render json: {success: false, alert: t('chat_rooms.error.chat_has_messages')}, status: :unprocessable_entity
    else
      @chat_rooms.destroy_all
      render_notification_success_json('deleted')
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def messages
    @chat_room, allocation_tag_id = ChatRoom.find(params[:id]), active_tab[:url][:allocation_tag_id]

    authorize! :show, ChatRoom, on: [allocation_tag_id]

    all_participants = @chat_room.participants.where(academic_allocations: { allocation_tag_id: allocation_tag_id })
    @researcher = current_user.is_researcher?(AllocationTag.find(allocation_tag_id).related)
    raise CanCan::AccessDenied if (all_participants.any? && all_participants.joins(:user).where(users: { id: current_user }).empty?) && !(ChatRoom.responsible?(allocation_tag_id, current_user.id)) && !(@researcher)

    @messages = @chat_room.messages.joins(allocation: [:user, :profile])
      .where('academic_allocations.allocation_tag_id = ? AND message_type = ?', allocation_tag_id, 1)
      .select('users.name AS user_name, users.nick AS user_nick, profiles.name AS profile_name, text, chat_messages.user_id, chat_messages.created_at')
      .order('created_at DESC')

  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def chat_room_params
      params.require(:chat_room).permit(:title, :description, :chat_type, :start_hour, :end_hour,
        schedule_attributes: [:id, :start_date, :end_date],
        academic_allocations_attributes: [:id, :allocation_tag_id, chat_participants_attributes: [id: [:id, :allocation_tag_id, :allocation_id, :_destroy]]])
    end

    def render_notification_success_json(method)
      render json: {success: true, notice: t(method, scope: 'chat_rooms.success')}
    end

end
