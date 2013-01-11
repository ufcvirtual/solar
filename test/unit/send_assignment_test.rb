require 'test_helper'

class  SendAssignmentTest < ActiveSupport::TestCase

  fixtures :assignments, :send_assignments

  test "nota deve ser maior ou igual a 0" do
    send_assignment = SendAssignment.create(:assignment_id => assignments(:a4).id, :user_id => users(:aluno1).id, :grade => -2)

    assert not(send_assignment.valid?)
    assert_equal send_assignment.errors[:grade].first, I18n.t(:greater_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 0)
  end

	test "nota deve ser menor ou igual a 10" do
    send_assignment = SendAssignment.create(:assignment_id => assignments(:a4).id, :user_id => users(:aluno1).id, :grade => 12)

    assert not(send_assignment.valid?)
    assert_equal send_assignment.errors[:grade].first, I18n.t(:less_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 10)
  end

  test "se tiver grupo, user_id deve ser nulo" do
    send_assignment = SendAssignment.create(:assignment_id => assignments(:a4).id, :user_id => users(:aluno1).id, :group_assignment_id => group_assignments(:a1).id)

    assert send_assignment.user_id.nil?
  end

  test "send assignment valido" do
    send_assignment = SendAssignment.create(:assignment_id => assignments(:a4).id, :user_id => users(:aluno1).id, :grade => 7)
    assert send_assignment.valid?
  end

end
