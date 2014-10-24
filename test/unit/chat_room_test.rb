require 'test_helper'

class ChatRoomTest < ActiveSupport::TestCase

  test "deve ter titulo" do
    chat = ChatRoom.create(start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day})

    assert chat.invalid?
    assert_equal chat.errors[:title].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter hora de inicio e fim" do
    chat = ChatRoom.create(title: "Chat 01", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day})

    assert chat.invalid?
    assert_equal chat.errors[:start_hour].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])

    chat = ChatRoom.create(title: "Chat 01", start_hour: "10:10", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day})

    assert chat.invalid?
    assert_equal chat.errors[:end_hour].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter hora de inicio e fim no formato definido" do
    chat = ChatRoom.create(title: "Chat 01", start_hour: "horario", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day})

    assert chat.invalid?
    assert_equal chat.errors[:start_hour].first, I18n.t(:invalid, scope: [:activerecord, :errors, :messages])

    chat = ChatRoom.create(title: "Chat 01", start_hour: "10:10", end_hour: "10:6", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day})

    assert chat.invalid?
    assert_equal chat.errors[:end_hour].first, I18n.t(:invalid, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter hora final posterior a inicial" do
    chat = ChatRoom.create(title: "Chat 01", start_hour: "10:12", end_hour: "10:10", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day})

    assert chat.invalid?
    assert_equal chat.errors[:end_hour].first, I18n.t(:range_hour_error, scope: [:chat_rooms, :error])
  end

  test "deve cadastrar chat_participants caso escolha algum" do
    chat = ChatRoom.new(title: "Chat 01", start_hour: "10:10", end_hour: "10:12", schedule_attributes: {start_date: Date.today, end_date: Date.today+1.day},
      academic_allocations_attributes: {'0' => {
          allocation_tag_id: 3,
          chat_participants_attributes: {"0" => {_destroy: 0, allocation_id: 2}}
        }
      }
    )

    chat.allocation_tag_ids_associations = [allocation_tags(:al3).id]

    # allocation_id 2 => Quimica I / Usuário do sistema

    assert chat.save
    assert_equal chat.participants.count, 1
  end

end