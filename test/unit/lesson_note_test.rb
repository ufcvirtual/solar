require 'test_helper'

class  LessonNoteTest < ActiveSupport::TestCase

  test 'descricao obrigatoria' do
    note = LessonNote.create name: 'Tópico 01', lesson_id: lessons(:pag_ufc).id, user_id: 7

    assert !note.valid?
    assert_equal note.errors[:description].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test 'aula obrigatoria' do
    note = LessonNote.create name: 'Tópico 01', description: 'Conteúdo da nota de aula', user_id: 7

    assert !note.valid?
    assert_equal note.errors[:lesson_id].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test 'usuario obrigatorio' do
    note = LessonNote.create name: 'Tópico 01', description: 'Conteúdo da nota de aula', lesson_id: lessons(:pag_ufc).id

    assert !note.valid?
    assert_equal note.errors[:user_id].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test 'nome unico para usuario e aula' do
    assert_raise RuntimeError do
      LessonNote.create name: 'Tópico 02', description: '<b>Conteúdo da nota de aula</b>', lesson_id: lessons(:pag_ufc).id, user_id: 7
    end
  end

end