require 'test_helper'

class CourseTest < ActiveSupport::TestCase

  test "criar" do
    course = Course.new code: "T1", name: "Teste 1"
    assert course.valid?
    assert course.save
    assert_not_nil course.id
  end

  test "nao criar - codigo e nome repetidos" do
    course1 = Course.create code: "T1", name: "Teste 1"
    course2 = Course.new code: "T1", name: "Teste 1"

    assert not(course2.valid?)
    assert_equal course2.errors.messages.keys.sort, [:name, :code].sort
  end

  test "nao atualizar se codigo for repetido" do
    code = courses(:c1).code
    course = Course.new name: "Curso 1", code: code

    assert not(course.valid?)
    assert course.errors.has_key?(:code)
  end

  test "deletar curso sem turmas relacionadas" do
    course = Course.new name: "Curso 1", code: "Codigo do curso"

    assert course.save
    assert course.destroy
  end

  test "nao deletar se tiver turmas relacionadas" do
    course = courses(:c2)

    assert not(course.destroy)
    assert_not_nil course.errors
  end

end
