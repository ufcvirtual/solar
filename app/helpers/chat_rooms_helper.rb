module ChatRoomsHelper

  def setup_chat_room(chat_room, allocations)
    (allocations - chat_room.participants.map(&:allocation).compact).each do |allocation|
      chat_room.participants.build(allocation: allocation)
    end
    chat_room.participants
  end

end
