require 'test_helper'

class  DiscussionTest < ActiveSupport::TestCase

  test "novo forum deve ter titulo" do
    discussion = Discussion.create(description: "discussion description", schedule_id: schedules(:schedule24).id)

    assert not(discussion.valid?)
    assert_equal discussion.errors[:name].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "novo forum deve ter descricao" do
    discussion = Discussion.create(name: "discussion name", schedule_id: schedules(:schedule24).id)

    assert not(discussion.valid?)
    assert_equal discussion.errors[:description].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "novo forum deve ter data final" do
    discussion = Discussion.create(name: "Forum sem data final", schedule_id: schedules(:schedule33).id)

    assert not(discussion.valid?)
    assert_equal discussion.errors[:final_date_presence].first, I18n.t(:mandatory_final_date, scope: [:discussions, :error])
  end

  test "novo forum deve ter titulo unico para a mesma allocation_tag" do
    discussion = Discussion.new(name: discussions(:forum_1).name, description: "discussion description", schedule_id: schedules(:schedule24).id)
    discussion.allocation_tag_ids_associations = [allocation_tags(:al3).id]
    assert (not discussion.valid?)

    assert_equal discussion.errors[:name].first, I18n.t(:existing_name, scope: [:discussions, :error])
  end

  test "se o forum esta fechado" do
    closed = discussions(:forum_7).closed?
    assert not(closed)

    closed = discussions(:forum_6).closed?
    assert closed
  end

end
