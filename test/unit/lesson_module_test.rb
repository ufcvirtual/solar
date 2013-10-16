require 'test_helper'

class LessonModuleTest < ActiveSupport::TestCase

  test 'deve ter nome preenchido' do 
    lesson_module = LessonModule.create()

    assert lesson_module.invalid?
    assert_equal lesson_module.errors[:name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test 'deve ter suas aulas transferidas para o padrao ao ser excluido' do 
    lesson_module_not_default = lesson_modules(:module3)
    lesson_module_default = lesson_modules(:module4)

    number_lessons_of_module_not_default = Lesson.find_all_by_lesson_module_id(lesson_modules(:module3)).size
    number_lessons_of_module_default = Lesson.find_all_by_lesson_module_id(lesson_modules(:module4)).size 

    assert_difference("LessonModule.count", -1) do
      lesson_module_not_default.destroy
    end

    assert (not LessonModule.exists?(lesson_module_not_default))
    assert Lesson.find_all_by_lesson_module_id(lesson_modules(:module4)).size == (number_lessons_of_module_not_default + number_lessons_of_module_default)
  end
  
end
