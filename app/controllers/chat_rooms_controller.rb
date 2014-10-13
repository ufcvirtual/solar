class ChatRoomsController < ApplicationController

  include SysLog::Actions

  layout false, except: :list

  before_filter :prepare_for_group_selection, only: :list

  before_filter :get_groups_by_allocation_tags, only: [:new, :create] do |controller|
    @allocations = @groups.map(&:students_participants).flatten.uniq
  end
  before_filter only: [:edit, :update, :show] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@chat_room = ChatRoom.find(params[:id]))
    @allocations = @groups.map(&:students_participants).flatten.uniq
  end

  def index
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :index, ChatRoom, on: @allocation_tags_ids

    @chat_rooms = ChatRoom.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).select("chat_rooms.*, schedules.start_date AS chat_start_date").order("chat_start_date, title").uniq
  end

  def new
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @chat_room = ChatRoom.new
    @chat_room.build_schedule(start_date: Date.current, end_date: Date.current)

    @academic_allocations = @chat_room.academic_allocations.build @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
    @academic_allocations.first.participants.build # escolha de participantes apenas para uma turma
  end

  def create
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(' ').flatten
    @chat_room = ChatRoom.new params[:chat_room]

    begin
      @chat_room.save!

      render json: {success: true, notice: t(:created, scope: [:chat_rooms, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @allocation_tags_ids = @allocation_tags_ids.join(" ")
      render :new
    end
  end

  def edit
    authorize! :update, ChatRoom, on: @allocation_tags_ids
  end

  def update
    authorize! :update, ChatRoom, on: @chat_room.academic_allocations.pluck(:allocation_tag_id)

    @chat_room.update_attributes!(params[:chat_room])

    render json: {success: true, notice: t(:updated, scope: [:chat_rooms, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render :edit
  end

  def destroy
    @chat_rooms = ChatRoom.where(id: params[:id].split(","))
    authorize! :destroy, ChatRoom, on: @chat_rooms.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten

    raise has_messages = true if @chat_rooms.map(&:can_destroy?).include?(false)

    ChatRoom.transaction do
      @chat_rooms.destroy_all
    end

    render json: {success: true, notice: t(:deleted, scope: [:chat_rooms, :success])}
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    render json: {success: false, alert: (has_messages ? t(:chat_has_messages, scope: [:chat_rooms, :error]) : t(:deleted, scope: [:chat_rooms, :error]))}, status: :unprocessable_entity
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

  def show
    authorize! :show, ChatRoom, on: @allocation_tags_ids
  end

  def messages
    @chat_room, allocation_tag_id = ChatRoom.find(params[:id]), active_tab[:url][:allocation_tag_id]

    authorize! :show, ChatRoom, on: [allocation_tag_id]

    all_participants = @chat_room.participants.where(academic_allocations: {allocation_tag_id: allocation_tag_id})
    raise CanCan::AccessDenied if (all_participants.any? and all_participants.joins(:user).where(users: {id: current_user}).empty?) and not(ChatRoom.responsible?(allocation_tag_id, current_user.id))

    @messages = @chat_room.messages.joins(allocation: [:user, :profile])
      .where('academic_allocations.allocation_tag_id = ? AND message_type = ?', allocation_tag_id, 1)
      .select('users.name AS user_name, users.nick AS user_nick, profiles.name AS profile_name, text, chat_messages.user_id, chat_messages.created_at')
      .order('created_at DESC')

  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

end
