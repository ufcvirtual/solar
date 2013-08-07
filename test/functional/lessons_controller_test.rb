require 'test_helper'
require 'zip/zip'
require 'fileutils'

class LessonsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor      = users(:editor)
    @professor   = users(:professor)
    @coordenador = users(:coorddisc)
    sign_in @editor
  end

  # criacao / edicao

  test "criar e editar uma aula do tipo link" do
    lesson = {name: 'lorem ipsum', address: 'http://aulatipolink1.com', type_lesson: Lesson_Type_Link, lesson_module_id: 1}
    params = {lesson: lesson, lesson_module_id: 1, allocation_tags_ids: allocation_tags(:al6), start_date: Time.now} # cria aula sem data final

    assert_difference(["Lesson.count", "Schedule.count"], 1) do
      post(:create, params)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'http://aulatipolink1.com'

    update = {id: Lesson.last.id, allocation_tags_ids: allocation_tags(:al6), lesson: {address: 'http://aulatipolink2.com'}, start_date: Time.now, end_date: (Time.now + 1.month)}

    assert_no_difference(["Lesson.count", "Schedule.count"]) do
      put(:update, update)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'http://aulatipolink2.com'
  end

  test "criar e editar uma aula do tipo arquivo" do
    lesson = {name: 'lorem ipsum', address: 'index.html', type_lesson: Lesson_Type_File, lesson_module_id: 1}
    params = {lesson: lesson, lesson_module_id: 1, allocation_tags_ids: allocation_tags(:al6), start_date: Time.now, end_date: (Time.now + 1.month)}

    assert_difference(["Lesson.count", "Schedule.count"], 1) do
      post(:create, params)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'index.html'

    update = {id: Lesson.last.id, allocation_tags_ids: allocation_tags(:al6), lesson: {address: 'index2.html'}, start_date: Time.now, end_date: (Time.now + 1.month)}

    assert_no_difference(["Lesson.count", "Schedule.count"]) do
      put(:update, update)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'index2.html'
  end

  test "nao criar aula com datas invalidas" do
    lesson = {name: 'lorem ipsum', address: 'index.html', type_lesson: Lesson_Type_File, lesson_module_id: 1}
    params = {lesson: lesson, lesson_module_id: 1, allocation_tags_ids: allocation_tags(:al6)} # sem data inicial

    assert_no_difference(["Lesson.count", "Schedule.count"], 1) do
      post(:create, params)
    end
    assert_template :new

    params = {lesson: lesson, lesson_module_id: 1, allocation_tags_ids: allocation_tags(:al6), start_date: (Time.now + 1.month), end_date: Time.now} 

    assert_no_difference(["Lesson.count", "Schedule.count"], 1) do
      post(:create, params)
    end
    assert_template :new    
  end

  ##
  # Download files
  ##

  # Usuário com permissão
  test "permitir zipar e realizar download de arquivos de aulas" do
    define_lesson_dir(lessons(:pag_index).id)

    lessons_ids = [lessons(:pag_index).id.to_s]
    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})

    zip_name = create_zip_name(lessons_ids)
    assert File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  # Usuário com permissão, mas não selecionou nenhuma aula
  test "nao permitir zipar e realizar download de arquivos de aulas se nenhuma for selecionada" do
    lessons_ids = []

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_template nothing:true

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

  test "nao permitir zipar e realizar download de arquivos de aulas se todas forem do tipo link" do
    lessons_ids = [lessons(:pag_ufc).id.to_s]

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_template nothing:true

    zip_name = create_zip_name(lessons_ids)
    assert not(File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name)))
  end

  test "nao permitir zipar e realizar download de arquivos de aulas se todas forem vazias" do
    define_lesson_dir(lessons(:pag_bbc).id, false)
    lessons_ids = [lessons(:pag_bbc).id.to_s]

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_template nothing:true

    zip_name = create_zip_name(lessons_ids)
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

  ##
  # Ordenacao
  ##

  test "mudar ordem das aulas 1 e 2" do
    assert_routing({method: :put, path: change_order_lesson_path(1, 2)}, { controller: "lessons", action: "order", id: "1", change_id: "2" })

    assert_equal Lesson.find(1,2).map(&:order), [1,2] # verificacao da ordem antes da mudanca
    put :order, {id: 1, change_id: 2}
    assert_equal Lesson.find(1,2).map(&:order), [2,1] # verificacao da ordem depois da mudanca
  end

  ##
  # Status
  ##

  test "liberar aula" do
    lesson = Lesson.find(lessons(:pag_index).id)
    FileUtils.touch(lesson.path(true).to_s)

    assert lesson.is_draft?

    put :change_status, {id: lesson.id, status: Lesson_Approved, allocation_tags_ids: [allocation_tags(:al6).id]}
    assert_response :success

    assert_equal Lesson_Approved, Lesson.find(lessons(:pag_index).id).status
    FileUtils.rm_rf(lesson.path(true).to_s)
  end

  test "nao liberar aula sem arquivo inicial" do
    lesson = Lesson.find(lessons(:pag_index).id)
    assert lesson.is_draft?

    FileUtils.rm_rf(lesson.path(true).to_s)

    put :change_status, {id: lesson.id, status: Lesson_Approved, allocation_tags_ids: [allocation_tags(:al6).id]}
    assert_response :unprocessable_entity

    assert_equal Lesson_Test, Lesson.find(lessons(:pag_index).id).status
  end


  test "setar aula como rascunho" do
    assert_routing({method: :put, path: change_status_lesson_path(lessons(:pag_virtual).id, Lesson_Approved)}, { controller: "lessons", action: "change_status", id: "#{lessons(:pag_virtual).id}", status: "#{Lesson_Approved}" })

    lesson = Lesson.find(lessons(:pag_virtual).id)
    assert_equal Lesson_Approved, lesson.status

    put :change_status, {id: lesson.id, status: Lesson_Test, allocation_tags_ids: [allocation_tags(:al6).id]}
    assert_response :success

    assert_equal Lesson_Test, Lesson.find(lessons(:pag_virtual).id).status
  end

  ##
  # Alterar módulo da aula
  ##

  test "alterar modulo da aula" do
    assert_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: allocation_tags(:al6).id, move_to_module: lesson_modules(:module5).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :success
  end

  test "nao alterar modulo da aula - sem acesso" do
    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al5).id], move_to_module: lesson_modules(:module8).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :unprocessable_entity
  end

  test "nao alterar modulo da aula - sem permissao" do
    sign_in @professor
    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: allocation_tags(:al6).id, move_to_module: lesson_modules(:module5).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :unprocessable_entity
  end

  test "nao alterar modulo da aula - dados invalidos" do
    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: allocation_tags(:al6).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :unprocessable_entity

    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: allocation_tags(:al6).id, move_to_module: lesson_modules(:module5).id, format: "json"}
      end
    end    

    assert_response :unprocessable_entity
  end

  private

    # Verifica se o diretório da aula escolhida está adequada aos testes
    def define_lesson_dir(lesson_id, with_files = true)
      lesson_file_path = File.join(Rails.root, "media", "lessons", lesson_id.to_s)
      Dir.mkdir(lesson_file_path) unless File.exist? lesson_file_path # verifica se diretório existe ou não; se não, cria.
      lesson_content_length = Dir.entries(lesson_file_path).length
      if with_files 
         Dir.mkdir(File.join(lesson_file_path, "Nova Pasta")) if lesson_content_length <= 2 # se estiver vazia, cria uma pasta dentro
      else
        FileUtils.rm_rf(lesson_file_path) # remove diretório com todo o seu conteúdo
        FileUtils.mkdir_p(lesson_file_path) # cria uma nova pasta para a aula
      end

    end

    def create_zip_name(lessons_ids)
      return Digest::SHA1.hexdigest(lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }.join) << '.zip'
    end

end
