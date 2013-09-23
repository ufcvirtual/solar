class ChatRoomsController < ApplicationController

  layout false, except: :list 

  def index
    @allocation_tags_ids = (params[:allocation_tags_ids].class == String ? params[:allocation_tags_ids].split(",") : params[:allocation_tags_ids])
    authorize! :index, ChatRoom, on: @allocation_tags_ids
    @chat_rooms = ChatRoom.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).order("title").uniq
  end

  def new
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @chat_room = ChatRoom.new
    @chat_room.build_schedule(start_date: Date.current, end_date: Date.current)

    groups = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten})
    @allocations = groups.map(&:students_participants).flatten.uniq
    @groups_codes = groups.map(&:code).uniq
  end

  def create
    authorize! :create, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @chat_room = ChatRoom.new params[:chat_room]

    begin
      ChatRoom.transaction do
        @chat_room.save!
        @chat_room.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:chat_rooms, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      groups = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten})
      @allocations = groups.map(&:students_participants).flatten.uniq
      @groups_codes = groups.map(&:code).uniq
      render :new
    end
  end

  def edit
    authorize! :update, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @chat_room = ChatRoom.find(params[:id])
    @schedule = @chat_room.schedule
    @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).map(&:students_participants).flatten.uniq
    @groups_codes = @chat_room.groups.map(&:code)
  end

  def update
    authorize! :update, ChatRoom, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    @chat_room = ChatRoom.find(params[:id])
    
    begin
      @chat_room.update_attributes!(params[:chat_room])

      render json: {success: true, notice: t(:updated, scope: [:chat_rooms, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).map(&:students_participants).flatten.uniq
      @groups_codes = @chat_room.groups.map(&:code)
      render :edit
    end

  end

  def destroy
    authorize! :destroy, ChatRoom, on: params[:allocation_tags_ids]

    begin
      @chat_rooms = ChatRoom.where(id: params[:id].split(","))
      raise has_messages = true if @chat_rooms.map(&:can_destroy?).include?(false)

      ChatRoom.transaction do
        @chat_rooms.destroy_all
      end

      render json: {success: true, notice: t(:deleted, scope: [:chat_rooms, :success])}
    rescue
      render json: {success: false, alert: (has_messages ? t(:chat_has_messages, scope: [:chat_rooms, :error]) : t(:deleted, scope: [:chat_rooms, :error]))}, status: :unprocessable_entity
    end
  end

  def list
    #authorize! :list, ChatRoom, on: @allocation_tags_ids

    @allocation_tags_ids = params[:allocation_tags_ids]
    
    alloc = Allocation.find_by_user_id_and_allocation_tag_id(current_user.id,@allocation_tags_ids)
    if !alloc.nil?
      @alloc = alloc.id
    end

    @responsible = ChatRoom.responsible?(@allocation_tags_ids,current_user.id) 
    @my_chats = ChatRoom.chats_user(@allocation_tags_ids,current_user.id)
    @other_chats = ChatRoom.chats_other_users(@allocation_tags_ids,current_user.id) unless @responsible
  end

end
