require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase

  test "retorna se a atividade ja terminou seu prazo" do    
    assert assignments(:a7).closed?
    assert not(assignments(:a2).closed?)
  end

  test "retorna se o usuario tem tempo extra na atividade" do
    assert assignments(:a7).extra_time?(allocation_tags(:al3), users(:professor).id)
    assert not(assignments(:a7).extra_time?(allocation_tags(:al3), users(:aluno1).id))
  end

  test "retorna alunos presentes em uma turma" do
    allocation_tags          = AllocationTag.find(assignments(:a7).academic_allocations.first.allocation_tag_id).related.join(',')
    students_of_class_method = AllocationTag.get_students(allocation_tags)
    students_of_class        = Allocation.all(:include => [:allocation_tag, :user, :profile], :conditions => ["cast( profiles.types & '#{Profile_Type_Student}' as boolean) 
      AND allocations.status = #{Allocation_Activated} AND allocation_tags.group_id IS NOT NULL AND allocation_tags.id IN (#{allocation_tags})"]).map(&:user_id)
    students_of_class        = User.select("name, id").find(students_of_class)

    assert_equal(students_of_class_method, students_of_class)
  end

  test "deve ter nome" do
    assignment = Assignment.create(enunciation: "Descricao", type_assignment: 0, schedule_id: schedules(:schedule27).id)

    assert assignment.invalid?
    assert_equal assignment.errors[:name].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "deve ter enunciado" do
    assignment = Assignment.create(name: "Trabalho 01", type_assignment: 0, schedule_id: schedules(:schedule27).id)

    assert assignment.invalid?
    assert_equal assignment.errors[:enunciation].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "deve definir tipo default quando nao passado" do
    assignment = Assignment.create(name: "Trabalho 01", enunciation: "Descricao", schedule_id: schedules(:schedule27).id)

    assert_equal assignment.type_assignment, 0
  end

  test "nome deve ter no maximo 1024 caracteres" do
    assignment = Assignment.create(name: "Trabalho 01"*94, enunciation: "Descricao", type_assignment: 0, schedule_id: schedules(:schedule27).id)

    assert assignment.invalid?
    assert_equal assignment.errors[:name].first, I18n.t(:too_long, scope: [:activerecord, :errors, :messages], count: 1024)
  end

end
