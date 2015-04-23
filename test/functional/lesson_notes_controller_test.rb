require 'test_helper'

class LessonNotesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    sign_in users(:aluno1)
  end

  test 'listar notas de aula' do
    get :index, { lesson_id: lessons(:pag_ufc).id }
    assert_response :success
    assert_equal assigns(:lesson_notes).count, 1
  end

  test 'nao listar notas de usuario diferente' do
    get :index, { lesson_id: lessons(:pag_ufc).id, user_id: 8 }
    assert_response :success
    assert_equal assigns(:lesson_notes).count, 1
  end

  test 'criar nota de aula' do
    assert_difference('LessonNote.where(user_id: 7).count') do
      post :create_or_update, { lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 03', description: 'Conteúdo da nota do tópico 03' } }
    end

    assert_equal I18n.t('lesson_notes.success.created_updated'), get_json_response('notice')
    assert_response :success
  end

  test 'tentar criar nota de aula para outro usuario' do
    assert_difference('LessonNote.where(user_id: 7).count') do
      assert_no_difference('LessonNote.where(user_id: 8).count') do
        post :create_or_update, { lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 03', description: 'Conteúdo da nota do tópico 03', user_id: 8 } }
      end
    end

    assert_equal I18n.t('lesson_notes.success.created_updated'), get_json_response('notice')
    assert_response :success
  end

  test 'editar nota de aula - com id' do
    assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 06').count") do
      assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 02').count", -1) do
        put :create_or_update, { id: 1, lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 06', description: 'Conteúdo da nota do tópico 03' } }
      end
    end

    assert_equal I18n.t('lesson_notes.success.created_updated'), get_json_response('notice')
    assert_response :success
  end

  test 'editar nota de aula - sem id' do
    assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 02', description: 'Conteúdo da nota do tópico 02 alterado').count") do
      assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 02', description: '<b>Conteúdo da nota de aula</b>').count", -1) do
        put :create_or_update, { lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 02', description: 'Conteúdo da nota do tópico 02 alterado' } }
      end
    end

    assert_equal I18n.t('lesson_notes.success.created_updated'), get_json_response('notice')
    assert_response :success
  end

  test 'tentar editar nota de aula de outro usuario - com id' do
    assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 06').count") do
      assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 02').count", -1) do
        put :create_or_update, { id: 1, lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 06', description: 'Conteúdo da nota do tópico 03', user_id: 8 } }
      end
    end

    assert_equal I18n.t('lesson_notes.success.created_updated'), get_json_response('notice')
    assert_response :success
  end

  test 'deletar uma nota' do
    assert_difference("LessonNote.where(user_id: 7, name: 'Tópico 02').count", -1) do
      delete :destroy, { id: lesson_notes(:note1).id }
    end

    assert_equal I18n.t('lesson_notes.success.removed'), get_json_response('notice')
    assert_response :success
  end

  test 'tentar deletar uma nota de outro usuario ' do
    assert_no_difference("LessonNote.where(user_id: 7, name: 'Tópico 02').count") do
      delete :destroy, { id: lesson_notes(:note2).id }
    end

    assert_equal I18n.t('lesson_notes.error.permission'), get_json_response('alert')
    assert_response :unprocessable_entity
  end

  test 'encontrar nota de aula por nome' do
    get :find, { lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 02' } }
    assert_response :success
    assert_equal assigns(:note), lesson_notes(:note1)
  end

  test 'tentar encontrar nota de aula de outro usuario por nome' do
    get :find, { lesson_note: { lesson_id: lessons(:pag_ufc).id, name: 'Tópico 02', user_id: 8 } }
    assert_response :success
    assert_equal assigns(:note), lesson_notes(:note1)
  end

  test 'download de pdf com notas de aula' do
    get :download, { lesson_id: lessons(:pag_ufc).id }
    assert_response :success
  end

  test 'tentar fazer download de pdf com notas de aula de outro usuario' do
    get :download, { lesson_id: lessons(:pag_ufc).id, id: lesson_notes(:note2).id }
    assert_response :redirect
    assert_equal flash[:alert], I18n.t('lesson_notes.error.pdf')
  end
  
end
