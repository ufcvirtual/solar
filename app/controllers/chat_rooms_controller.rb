class ChatRoomsController < ApplicationController

  include SysLog::Actions

  layout false, except: :list
  authorize_resource only: :list

  before_filter :prepare_for_group_selection, only: :list

  def index
    @allocation_tags_ids = ( params.include?(:groups_by_offer_id) ? Offer.find(params[:groups_by_offer_id]).groups.map(&:allocation_tag).map(&:id) : params[:allocation_tags_ids] )
    authorize! :index, ChatRoom, on: @allocation_tags_ids

    @chat_rooms = ChatRoom.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).order("title").uniq
  end

  def new
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @chat_room = ChatRoom.new
    @chat_room.build_schedule(start_date: Date.current, end_date: Date.current)

    @academic_allocations = @chat_room.academic_allocations.build @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
    @academic_allocations.first.participants.build # escolha de participantes apenas para uma turma

    groups = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids})
    @allocations  = groups.map(&:students_participants).flatten.uniq
    @groups_codes = groups.pluck(:code).uniq
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
      groups = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten})
      @allocations  = groups.map(&:students_participants).flatten.uniq
      @groups_codes = groups.pluck(:code).uniq
      @allocation_tags_ids = @allocation_tags_ids.join(" ")

      render :new
    end
  end

  def edit
    authorize! :update, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @chat_room = ChatRoom.find(params[:id])
    @schedule  = @chat_room.schedule
    @allocations  = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).map(&:students_participants).flatten.uniq
    @groups_codes = @chat_room.groups.pluck(:code)
  end

  def update
    @allocation_tags_ids, @chat_room = params[:allocation_tags_ids], ChatRoom.find(params[:id])
    authorize! :update, ChatRoom, on: @chat_room.academic_allocations.pluck(:allocation_tag_id)

    @chat_room.update_attributes!(params[:chat_room])

    render json: {success: true, notice: t(:updated, scope: [:chat_rooms, :success])}
  rescue ActiveRecord::AssociationTypeMismatch
    render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  rescue
    @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).map(&:students_participants).flatten.uniq
    @groups_codes = @chat_room.groups.pluck(:code)
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
    authorize! :show, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @chat_room    = ChatRoom.find(params[:id])
    @groups_codes = @chat_room.groups.pluck(:code)
  end

  def messages
    @chat_room, allocation_tag_id = ChatRoom.find(params[:id]), active_tab[:url][:allocation_tag_id]

    authorize! :show, ChatRoom, on: [allocation_tag_id]

    all_participants = @chat_room.participants.where(academic_allocations: {allocation_tag_id: allocation_tag_id})
    raise CanCan::AccessDenied if all_participants.any? and all_participants.joins(:user).where(users: {id: current_user}).empty?

    @messages = @chat_room.messages.joins(allocation: [:user, :profile])
      .where('academic_allocations.allocation_tag_id = ? AND message_type = ?', allocation_tag_id, 1)
      .select('users.name AS user_name, users.nick AS user_nick, profiles.name AS profile_name, text, chat_messages.user_id, chat_messages.created_at')
      .order('created_at DESC')

  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

end
