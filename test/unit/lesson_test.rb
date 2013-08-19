require 'test_helper'
require 'fileutils'

class LessonTest < ActiveSupport::TestCase
  fixtures :lessons

  test "aula deve ter nome" do
    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, order: 99, type_lesson: Lesson_Type_Link, address: "www.google.com")

    assert not(lesson.valid?)
    assert_equal lesson.errors[:name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "aula deve ter url valida se for de link" do
    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_Link)

    assert not(lesson.valid?)
    assert_equal lesson.errors[:address].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])

    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_Link, address: "google")

    assert not(lesson.valid?)
    assert_equal lesson.errors[:address].first, I18n.t(:invalid, :scope => [:activerecord, :errors, :models, :lesson, :attributes, :address])
  end


  test "criando aula e verificando arquivos" do
    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_File, address: "")
    
    assert File.exist?(lesson.path(true))
  end

  test "criando aula completando a url com http quando necessario" do
    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_Link, address: "www.google.com")
    
    assert lesson.valid?
    assert_equal "http://www.google.com", lesson.address

    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_Link, address: "https://www.google.com")
    
    assert lesson.valid?
    assert_equal "https://www.google.com", lesson.address
  end

  test "alterando tipo e verificando existencia de arquivos" do
    lesson = Lesson.create(lesson_module_id: lesson_modules(:module1).id, name: "Lorem ipsum", order: 99, type_lesson: Lesson_Type_File, address: "")

    
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

  test "aula deve ter um modulo" do
    lesson = Lesson.create(order: 99, name: "Lesson sem modulo", type_lesson: Lesson_Type_Link, address: "www.google.com")

    assert not(lesson.valid?)
    assert_equal lesson.errors[:lesson_module].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

end