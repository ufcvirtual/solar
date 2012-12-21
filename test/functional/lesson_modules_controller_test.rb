require 'test_helper'

class LessonModulesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor    = users(:editor)
    @professor = users(:professor)
    sign_in @editor
  end

  # New/Create

  test 'cria modulo' do 
    get :new, {:allocation_tags_ids => [allocation_tags(:al2).id]} 
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:module)

    assert_difference("LessonModule.count", +1) do 
      post(:create, {:lesson_module => {:name => "Modulo 01"}, :allocation_tags_ids => assigns(:allocation_tags_ids)})
    end

    assert_response :success
  end

  test 'nao cria modulo - sem permissao' do 
    sign_in users(:professor)
    get :new, {:allocation_tags_ids => [allocation_tags(:al2).id]} 
    assert_not_nil assigns(:allocation_tags_ids)
    assert_nil assigns(:module)

    assert_no_difference("LessonModule.count") do 
      post(:create, {:lesson_module => {:name => "Modulo 01"}, :allocation_tags_ids => assigns(:allocation_tags_ids)})
    end

    assert_response :error
  end

  # Edit/Update

  test 'edita modulo' do 
    get :edit, {:id => lesson_modules(:module2).id, :allocation_tags_ids => [allocation_tags(:al2).id]} 
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:module)

    put(:update, {:id => assigns(:module).id, :lesson_module => {:name => "Modulo 01"}, :allocation_tags_ids => assigns(:allocation_tags_ids)})

    assert_response :success
    # assert_equal "Modulo 01", lesson_modules(:module3).name
  end

  test 'nao edita modulo - sem permissao' do 
    sign_in @professor
    get :edit, {:id => lesson_modules(:module2).id, :allocation_tags_ids => [allocation_tags(:al2).id]} 
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:module)

    put(:update, {:id => assigns(:module).id, :lesson_module => {:name => "Modulo 01"}, :allocation_tags_ids => assigns(:allocation_tags_ids)})

    assert_response :error
    assert_not_equal "Modulo 01", lesson_modules(:module3).name
  end

  # Destroy

  test 'deleta modulo - com aulas' do 
    assert_difference("LessonModule.count", -1) do
      assert_difference("Lesson.count", -lesson_modules(:module3).lessons.size) do
        get :destroy, {:id => lesson_modules(:module3).id, :allocation_tags_ids => [allocation_tags(:al2).id]} 
      end
    end

    assert_response :success
  end

  test 'nao deleta modulo - aula ativada' do 
    assert_no_difference(["LessonModule.count", "Lesson.count"]) do
      get :destroy, {:id => lesson_modules(:module2).id, :allocation_tags_ids => [allocation_tags(:al2).id]} 
    end

    assert_response :error
  end

  test 'nao deleta modulo - sem permissao' do 
    sign_in @professor

    assert_no_difference(["LessonModule.count", "Lesson.count"]) do
      get :destroy, {:id => lesson_modules(:module2).id, :allocation_tags_ids => [allocation_tags(:al2).id]} 
    end

    assert_response :error
  end

end