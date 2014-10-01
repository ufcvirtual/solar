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
