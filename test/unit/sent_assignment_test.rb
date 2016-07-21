require 'test_helper'

class  AcademicAllocationUserTest < ActiveSupport::TestCase

  fixtures :assignments, :academic_allocation_users, :academic_allocations

  test "nota deve ser maior ou igual a 0" do
    academic_allocation_user = AcademicAllocationUser.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :grade => -2)

    assert !academic_allocation_user.valid?
    assert_equal academic_allocation_user.errors[:grade].first, I18n.t(:greater_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 0)
  end

	test "nota deve ser menor ou igual a 10" do
    academic_allocation_user = AcademicAllocationUser.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :grade => 12)

    assert !academic_allocation_user.valid?
    assert_equal academic_allocation_user.errors[:grade].first, I18n.t(:less_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 10)
  end

  test "se tiver grupo, user_id deve ser nulo" do
    academic_allocation_user = AcademicAllocationUser.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :group_assignment_id => group_assignments(:a1).id)

    assert academic_allocation_user.user_id.nil?
  end

  test "send assignment valido" do
    academic_allocation_user = AcademicAllocationUser.create(:academic_allocation_id => academic_allocations(:acaal7).id, :user_id => users(:aluno1).id, :grade => 7)
    assert academic_allocation_user.valid?
  end

end
