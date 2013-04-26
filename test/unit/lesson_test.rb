require 'test_helper'
require 'fileutils'

class LessonTest < ActiveSupport::TestCase
  fixtures :lessons

  test "criando aula e verificando arquivos" do
    lesson = Lesson.create(name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_File, address: "")
    
    assert File.exist?(lesson.path(true))
  end

  test "alterando tipo e verificando existencia de arquivos" do
    lesson = Lesson.create(name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_File, address: "")
    
    assert File.exist?(lesson.path(true))
    
    lesson.type_lesson = Lesson_Type_Link
    lesson.save

    assert not(File.exist?(lesson.path(true)))
  end

  test "deletando aula com arquivos" do
    lesson = lessons(:lesson_files_to_delete)
    path = lesson.path(true).join('1','2','3')
    FileUtils.mkdir_p(path)

    assert File.exist?(path)

    lesson.destroy    
    assert Lesson.where(id: lesson.id).empty?
    assert not(File.exist?(path))
  end

  test "nao liberar aula sem arquivo inicial" do
    lesson = lessons(:pag_index)

    assert lesson.is_file?
    assert lesson.is_draft?

    lesson.status = Lesson_Approved
    lesson.save

    assert_equal lesson.errors.full_messages.first, "Um arquivo inicial deve ser definido."
  end

end