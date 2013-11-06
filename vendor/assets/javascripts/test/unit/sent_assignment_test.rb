require 'test_helper'

class  SentAssignmentTest < ActiveSupport::TestCase

  fixtures :assignments, :sent_assignments, :academic_allocations

  test "nota deve ser maior ou igual a 0" do
    sent_assignment = SentAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :grade => -2)

    assert not(sent_assignment.valid?)
    assert_equal sent_assignment.errors[:grade].first, I18n.t(:greater_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 0)
  end

	test "nota deve ser menor ou igual a 10" do
    sent_assignment = SentAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :grade => 12)

    assert not(sent_assignment.valid?)
    assert_equal sent_assignment.errors[:grade].first, I18n.t(:less_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 10)
  end

  test "se tiver grupo, user_id deve ser nulo" do
    sent_assignment = SentAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :group_assignment_id => group_assignments(:a1).id)

    assert sent_assignment.user_id.nil?
  end

  test "send assignment valido" do
    sent_assignment = SentAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :grade => 7)
    assert sent_assignment.valid?
  end

end
