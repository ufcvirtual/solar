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
    @chat_room.participants.build

    @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
  end

  def create
    @allocation_tags_ids = params[:allocation_tags_ids].split(" ")
    @chat_room = ChatRoom.new params[:chat_room]
    @chat_room.chat_type = (not @chat_room.participants.empty?)

    begin
      ChatRoom.transaction do
        @chat_room.save!
        @chat_room.academic_allocations.create @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:chat_rooms, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception => error
      raise "#{error}"
      @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
      @chat_room.participants.build if @chat_room.participants.empty?
      render :new
    end
  end

  def edit
    @chat_room = ChatRoom.find(params[:id])
    @schedule = @chat_room.schedule
    @participants = @chat_room.allocations
    @chat_room.participants.build if @chat_room.participants.empty?
    @allocations = Group.joins(:allocation_tag).where(allocation_tags: {id: params[:allocation_tags_ids].flatten}).map(&:students_participants).flatten.uniq
  end

  def update

    @chat_room = ChatRoom.find(params[:id])
    
    begin
      participants = @chat_room.participants.map(&:allocation_id)
      participants_edition = params[:chat_room][:participants_attributes].collect{|a| a[1][:allocation_id].to_i unless a[1][:allocation_id]=="0"}.compact.uniq

      # os participantes selecionados que não existiam, são criados
      (participants_edition - participants).each do |allocation_id|
        @chat_room.participants.create!(allocation_id: allocation_id)
      end

      # os participantes que existiam e não foram selecionados, são removidos
      (participants - participants_edition).each do |allocation_id|
        @chat_room.participants.where(allocation_id: allocation_id).first.destroy
      end      

        
      params[:chat_room].delete(:participants_attributes)

      @chat_room.update_attributes!(params[:chat_room])

      render json: {success: true, notice: t(:updated, scope: [:chat_rooms, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue Exception => error
      raise "#{error}"
      @participants = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:students_participants).flatten
      @participants = @participants.map(&:user).uniq
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
