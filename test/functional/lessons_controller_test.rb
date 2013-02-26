require 'test_helper'
require 'zip/zip'

class LessonsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor      = users(:editor)
    @professor   = users(:professor)
    @coordenador = users(:coorddisc)
    sign_in @editor
  end

  def create_zip_name(lessons_ids)
    return Digest::SHA1.hexdigest(lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }.join) << '.zip'
  end

  ##
  # Download files
  ##

  # Usuário com permissão
  test "permitir zipar e realizar download de arquivos de aulas" do
    lessons_ids = [lessons(:pag_ufc).id.to_s, lessons(:pag_uol).id.to_s]

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_response :success

    zip_name = create_zip_name(lessons_ids)
    assert File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  # Usuário com permissão, mas não selecionou nenhuma aula # CONCLUIR
  test "nao permitir zipar e realizar download de arquivos de aulas se nenhuma for selecionada" do
    lessons_ids = []

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:must_select_lessons, :scope => [:lessons, :notifications])

    zip_name = create_zip_name(lessons_ids)
    assert not(File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name)))
  end

  # Usuário sem permissão
  test "nao permitir zipar e realizar download de arquivos de aulas para usuario sem permissao" do
    sign_in @professor

    lessons_ids = [lessons(:pag_ufc).id.to_s, lessons(:pag_uol).id.to_s]
    zip_name    = create_zip_name(lessons_ids)
    FileUtils.rm File.join(Rails.root.to_s, 'tmp', zip_name), force: true # deleta arquivo para testar se foi criado

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_redirected_to home_path
    assert_equal I18n.t(:no_permission), flash[:alert]

    assert not(File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name)))
  end

  ##
  # List
  ##

  test "exibir cadastro de modulos e aulas para um usuario com permissao" do
    sign_in @coordenador
    get :list, { :allocation_tags_ids => [allocation_tags(:al5).id], :what_was_selected => [false, true, false, false] }
    assert_response :success
    assert_not_nil assigns(:allocation_tags)
  end

  test "nao exibir cadastro de modulos e aulas para um usuario sem permissao" do
    sign_in users(:user2)

    get :list, { :allocation_tags_ids => [allocation_tags(:al5).id], :what_was_selected => [false, true, false, false] }
    assert_nil assigns(:allocation_tags)
    assert_response :error
  end

  test "rota para extrair arquivos de aula" do
    assert_routing extract_file_lesson_path("1", "file", "zip"), {
      controller: "lessons", action: "extract_files", id: "1", file: "file", extension: "zip"
    }
  end

  ##
  # Extract files
  ##

  test "extrair arquivo de aula" do
    sign_in @coordenador

    lesson_id = lessons(:pag_goo).id.to_s
    file_name = 'lesson_test.zip'

    # copiando arquivo de aula de teste para o local adequado
    FileUtils.mkdir_p(File.join(Lesson::FILES_PATH, lesson_id)) # criando diretorio da aula
    FileUtils.cp(File.join(Rails.root, 'test', 'fixtures', 'files', 'lessons', file_name), File.join(Lesson::FILES_PATH, lesson_id, file_name))

    get :extract_files, {id: lesson_id, file: "lesson_test", extension: "zip", format: "json"}

    assert_response :success
    assert_equal response.body, {success: true}.to_json
  end

  ##
  # Ordenacao
  ##

  test "mudar ordem das aulas 1 e 2" do
    # checando a rota
    assert_routing({method: :put, path: change_order_lesson_path(1, 2)}, { controller: "lessons", action: "order", id: "1", change_id: "2" })

    assert_equal Lesson.find(1,2).map(&:order), [1,2] # verificacao da ordem antes da mudanca
    put :order, {id: 1, change_id: 2}
    assert_equal Lesson.find(1,2).map(&:order), [2,1] # verificacao da ordem depois da mudanca
  end

end
