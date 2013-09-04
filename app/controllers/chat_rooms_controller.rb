class ChatRoomsController < ApplicationController

  layout false

  def index
    @allocation_tags_ids = params[:allocation_tags_ids]
    @chat_rooms = ChatRoom.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).order("title").uniq
  end

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    @chat_room = ChatRoom.new
    @chat_room.build_schedule(start_date: Date.current, end_date: Date.current)
    @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
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
      @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
      render :new
    end
  end

  def edit
    @chat_room = ChatRoom.find(params[:id])
    @schedule = @chat_room.schedule
    @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: params[:allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
  end

  def update
    @chat_room = ChatRoom.find(params[:id])
    
    begin
      @chat_room.update_attributes!(params[:chat_room])

      render json: {success: true, notice: t(:updated, scope: [:chat_rooms, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue 
      @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: params[:allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
      render :edit
    end

  end

  def destroy

    begin
      ChatRoom.transaction do
        @chat_rooms = ChatRoom.where(id: params[:id].split(",")).map(&:destroy)
      end
      render json: {success: true, notice: t(:deleted, scope: [:chat_rooms, :success])}
    rescue
      render json: {success: false, alert: t(:deleted, scope: [:chat_rooms, :error])}, status: :unprocessable_entity
    end

  end

end
