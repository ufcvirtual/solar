require 'test_helper'

class  DiscussionTest < ActiveSupport::TestCase

  fixtures :discussions, :schedules, :allocation_tags

  #test "novo schedule deve ter data final" do
  #  schedule = Schedule.create(:start_date => schedules(:schedule24).start_date)

  #  assert (not schedule.valid?)
  #  assert_equal schedule.errors[:end_date].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  #end
  
  test "novo forum deve ter titulo" do
    discussion = Discussion.create(:description => "discussion description", :schedule_id => schedules(:schedule24).id, :allocation_tag_id => allocation_tags(:al3).id)

    assert not(discussion.valid?)
    assert_equal discussion.errors[:name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "novo forum deve ter descricao" do
    discussion = Discussion.create(:name => "discussion name", :schedule_id => schedules(:schedule24).id, :allocation_tag_id => allocation_tags(:al3).id)

    assert not(discussion.valid?)
    assert_equal discussion.errors[:description].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "novo forum deve ter data final" do
    discussion = Discussion.create(:name => "Forum sem data final", :schedule_id => schedules(:schedule33).id, :allocation_tag_id => allocation_tags(:al3).id)

    assert (discussion.valid?)
    assert_equal discussion.errors[:base].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "novo forum deve ter titulo unico para a mesma allocation_tag" do
    discussion1 = Discussion.create(:name => "discussion name", :description => "discussion description", :schedule_id => schedules(:schedule24).id, :allocation_tag_id => allocation_tags(:al3).id)
    assert discussion1.valid?

    discussion2 = Discussion.create(:name => "discussion name", :description => "discussion description", :schedule_id => schedules(:schedule24).id, :allocation_tag_id => allocation_tags(:al3).id)

    assert not(discussion2.valid?)
    assert_equal discussion2.errors[:base].first, I18n.t(:existing_name, :scope => [:discussion, :errors])
  end

  # test "forum concluido com postagem nao pode ser excluido" do
  #   discussion = discussions(:forum_6)
  #   assert_no_difference("Discussion.count") do
  #     discussion.destroy
  #   end

  #   assert Discussion.exists?(discussion)
  # end

  test "forum iniciado nao pode ser excluido" do
    discussion = discussions(:forum_1)
    assert_no_difference("Discussion.count") do
      discussion.destroy
    end

    assert Discussion.exists?(discussion)
  end

  test "exclusao de forum com sucesso" do
    discussion = discussions(:forum_7)
    assert_difference("Discussion.count", -1) do
      discussion.destroy
    end

    assert not(Discussion.exists?(discussion))
  end

  test "se o forum esta fechado" do
    closed = discussions(:forum_7).closed?
    assert not(closed)

    closed = discussions(:forum_6).closed?
    assert closed
  end

end
