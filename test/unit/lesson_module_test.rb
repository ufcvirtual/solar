require 'test_helper'

class LessonModuleTest < ActiveSupport::TestCase

  test 'deve ter nome preenchido' do 
    lesson_module = LessonModule.create(:allocation_tag_id => allocation_tags(:al1).id)

    assert lesson_module.invalid?
    assert_equal lesson_module.errors[:name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test 'deve ter nome unico para uma allocation_tag_id' do 
    lesson_module1 = LessonModule.create(:name => "Modulo 01", :allocation_tag_id => allocation_tags(:al1).id)
    lesson_module2 = LessonModule.create(:name => "Modulo 01", :allocation_tag_id => allocation_tags(:al2).id)
    lesson_module3 = LessonModule.create(:name => "Modulo 01", :allocation_tag_id => allocation_tags(:al1).id)

    assert lesson_module2.valid?
    assert lesson_module3.invalid?

    assert_equal lesson_module3.errors[:name].first, I18n.t(:existing_name, :scope => [:lesson_modules, :errors])
  end

  test 'deve ter suas aulas excluidas ao ser excluido' do 
    lesson_module = lesson_modules(:module3)

    assert_difference("LessonModule.count", -1) do
      lesson_module.destroy
    end

    assert (not LessonModule.exists?(lesson_module))
    assert Lesson.find_all_by_lesson_module_id(lesson_modules(:module3)).empty?
  end
  
end
