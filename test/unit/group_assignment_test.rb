require 'test_helper'

class  GroupAssignmentTest < ActiveSupport::TestCase

  fixtures :group_assignments, :assignments, :academic_allocations,:allocation_tags,:groups

  # Validações

  test "nome do grupo deve ser preenchido" do
    group_assignment = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id)

    assert (not group_assignment.valid?)
    assert_equal group_assignment.errors[:group_name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end   

  test "nome do grupo nao pode exceder 20 caracteres" do
    group_assignment = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :group_name => "abcdefghijklmnopqrstuvwxyz")

    assert (not group_assignment.valid?)
    assert_equal group_assignment.errors[:group_name].first, I18n.t(:too_long, :scope => [:activerecord, :errors, :messages], :count => 20)
  end

  test "nome do grupo deve ser unico para uma atividade" do
    group_assignment1 = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :group_name => "Grupo 1")
    group_assignment2 = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :group_name => "Grupo 1")

    assert (group_assignment1.valid?)
    assert (not group_assignment2.valid?)
    assert_equal group_assignment2.errors[:group_name].first, I18n.t(:existing_name_error, :scope => [:assignment, :group_assignments])
  end  

  test "nome do grupo nao precisa ser unico para atividades diferentes" do
    group_assignment1 = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :group_name => "Grupo 1")
    group_assignment2 = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal8).id, :group_name => "Grupo 1")

    assert (group_assignment1.valid?)
    assert (group_assignment2.valid?)
  end

  test "novo grupo valido" do
    group_assignment = GroupAssignment.create(:academic_allocation_id => academic_allocations(:acaal7).id, :group_name => "grupo 1")
    assert group_assignment.valid?
  end

  # Métodos

  test "nao pode excluir grupo que seja falso em 'can_remove_group'" do
    can_remove_group = group_assignments(:a5).can_remove?
    assert (not can_remove_group)
  end

  test "pode excluir grupo que seja true em 'can_remove_group'" do
    can_remove_group = group_assignments(:a4).can_remove?
    assert (can_remove_group)
  end

end
