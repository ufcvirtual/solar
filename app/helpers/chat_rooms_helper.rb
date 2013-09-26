module ChatRoomsHelper

  def setup_chat_room(chat_room, allocations)
    (allocations - chat_room.participants.map(&:allocation).compact).each do |allocation|
      chat_room.participants.build(allocation: allocation)
    end
    chat_room.participants
  end

  def participants(chat_room_id)
    p = ChatParticipant.joins(:user)
      .select("chat_participants.*, users.name, users.nick")
      .where(chat_room_id: chat_room_id).uniq
      .order("users.name")
  end

end
