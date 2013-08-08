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
    can_remove_group = GroupAssignment.can_remove_group?(group_assignments(:a5).id)
    assert (not can_remove_group)
  end

  test "pode excluir grupo que seja true em 'can_remove_group'" do
    can_remove_group = GroupAssignment.can_remove_group?(group_assignments(:a4).id)
    assert (can_remove_group)
  end

  test "recupera alunos sem grupo" do
    allocation_tag = groups(:g3).allocation_tag
    students_without_groups = assignments(:a5).students_without_groups(allocation_tag)
    academic_allocation = AcademicAllocation.find_by_allocation_tag_id_and_academic_tool_id_and_academic_tool_type(allocation_tag.id,assignments(:a5).id, 'Assignment')
    students_with_groups    = GroupParticipant.all(conditions: {:group_assignment_id => academic_allocation.group_assignment_ids}).map(&:user_id)
    students_without_groups.each do |student|
      assert (not students_with_groups.include?(student.id))
    end
  end

  test "recupera todas as atividades de grupo de uma turma" do 
    all_group_assignments_method = GroupAssignment.all_by_group_id(groups(:g3).id)
    all_group_assignments = Assignment.all(
      select: [:id, :name, :enunciation, :schedule_id],
      include: [:schedule, :group_assignments, :academic_allocations], 
      conditions: {type_assignment: Assignment_Type_Group, academic_allocations: {allocation_tag_id: groups(:g3).allocation_tag.id}}, 
      order: ["schedules.start_date"])

    assert_equal(all_group_assignments, all_group_assignments_method)
  end

end
