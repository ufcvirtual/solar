require 'test_helper'
require 'zip'
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

  test 'criar e editar uma aula do tipo link' do
    # aula sem data final
    lesson = { name: 'lorem ipsum', address: 'http://aulatipolink1.com', type_lesson: Lesson_Type_Link, lesson_module_id: 1, schedule_attributes: { start_date: Time.now } }
    params_group = { lesson: lesson.merge(lesson_module_id: 1), allocation_tags_ids: "#{allocation_tags(:al6).id}" }
    params_offer = { lesson: lesson.merge(lesson_module_id: 5), allocation_tags_ids: "#{allocation_tags(:al6).id}" }

    assert_difference(['Lesson.count', 'Schedule.count'], 2) do
      post(:create, params_group)
      post(:create, params_offer)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'http://aulatipolink1.com'

    last_lesson = Lesson.last
    update = { id: last_lesson.id, allocation_tags_ids: "#{allocation_tags(:al6).id}", lesson: { address: 'http://aulatipolink2.com', schedule_attributes: { id: last_lesson.schedule.id, start_date: Time.now, end_date: (Time.now + 1.month) } } }

    assert_no_difference(['Lesson.count', 'Schedule.count']) do
      put(:update, update)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'http://aulatipolink2.com'
  end

  test 'criar e editar uma aula do tipo arquivo' do
    lesson = { name: 'lorem ipsum', address: 'index.html', type_lesson: Lesson_Type_File, lesson_module_id: 1, schedule_attributes: { start_date: Time.now, end_date: (Time.now + 1.month) } }
    params = { lesson: lesson, allocation_tags_ids: "#{allocation_tags(:al6).id}" }

    assert_difference(['Lesson.count', 'Schedule.count'], 1) do
      post(:create, params)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'index.html'

    update = { id: Lesson.last.id, allocation_tags_ids: "#{allocation_tags(:al6).id}", lesson: { address: 'index2.html' }, start_date: Time.now, end_date: (Time.now + 1.month) }

    assert_no_difference(['Lesson.count', 'Schedule.count']) do
      put(:update, update)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'index2.html'
  end

  test 'nao deve editar aulas privadas de outro dono' do
    assert_no_difference(['Lesson.count', 'Schedule.count']) do
      put :update, { id: lessons(:lesson_with_files).id, allocation_tags_ids: "#{allocation_tags(:al2).id}", lesson: { name: 'alterando nome'}, start_date: Time.now, end_date: (Time.now + 1.month) }
    end

    assert_equal Lesson.find(lessons(:lesson_with_files).id).name, lessons(:lesson_with_files).name
    assert_response :unauthorized
  end

  test 'criar e editar proprias aulas privadas' do
    lesson = { name: 'lorem ipsum', address: 'index.html', type_lesson: Lesson_Type_File, privacy: true, lesson_module_id: 1, schedule_attributes: { start_date: Time.now, end_date: (Time.now + 1.month) } }
    params = { lesson: lesson, allocation_tags_ids: "#{allocation_tags(:al6).id}" }

    assert_difference(['Lesson.count', 'Schedule.count'], 1) do
      post(:create, params)
    end
    assert_response :ok
    assert_equal Lesson.last.address, 'index.html'

    update = { id: Lesson.last.id, allocation_tags_ids: "#{allocation_tags(:al6).id}", lesson: { address: 'index2.html' }, start_date: Time.now, end_date: (Time.now + 1.month) }

    assert_no_difference(['Lesson.count', 'Schedule.count']) do
      put(:update, update)
    end

    assert_response :ok
    assert_equal Lesson.last.address, 'index2.html'
  end

  test "nao criar aula com datas invalidas" do
    lesson = { name: 'lorem ipsum', address: 'index.html', type_lesson: Lesson_Type_File, lesson_module_id: 1 }
    params = { lesson: lesson, lesson_module_id: 1, allocation_tags_ids: "#{allocation_tags(:al6).id}", start_date: (Time.now + 1.month), end_date: Time.now }

    assert_no_difference(['Lesson.count', 'Schedule.count']) do
      post(:create, params)
    end

    assert_template :new
  end

  # Usuário com permissão
  test "permitir zipar e realizar download de arquivos de aulas" do
    define_lesson_dir(lessons(:pag_index).id)
    FileUtils.touch(lessons(:pag_index).path(true)) # criando arquivo no dir da aula

    lessons_ids = [lessons(:pag_index).id.to_s]
    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => "#{allocation_tags(:al6).id}"})

    zip_name = create_zip_name(lessons_ids)
    assert File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  # Usuário com permissão, mas não selecionou nenhuma aula
  test "nao permitir zipar e realizar download de arquivos de aulas se nenhuma for selecionada" do
    lessons_ids = []

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => "#{allocation_tags(:al6).id}"})
    assert_template nothing: true

    zip_name = create_zip_name(lessons_ids)
    assert !File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  # Usuário sem permissão
  test "nao permitir zipar e realizar download de arquivos de aulas para usuario sem permissao" do
    sign_in @professor

    lessons_ids = [lessons(:pag_ufc).id.to_s, lessons(:pag_uol).id.to_s]
    zip_name    = create_zip_name(lessons_ids)
    FileUtils.rm File.join(Rails.root.to_s, 'tmp', zip_name), force: true # deleta arquivo para testar se foi criado

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => "#{allocation_tags(:al6).id}"})
    assert_redirected_to home_path
    assert_equal I18n.t(:no_permission), flash[:alert]

    assert !File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  test "nao permitir zipar e realizar download de arquivos de aulas se todas forem do tipo link" do
    lessons_ids = [lessons(:pag_ufc).id.to_s]

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => "#{allocation_tags(:al6).id}"})
    assert_template nothing:true

    zip_name = create_zip_name(lessons_ids)
    assert !File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  test "nao permitir zipar e realizar download de arquivos de aulas se todas forem vazias" do
    define_lesson_dir(lessons(:pag_bbc).id, false)
    lessons_ids = [lessons(:pag_bbc).id.to_s]

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => "#{allocation_tags(:al6).id}"})
    assert_template nothing: true

    zip_name = create_zip_name(lessons_ids)
    assert !File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  ##
  # List
  ##

  test "exibir cadastro de modulos e aulas para um usuario com permissao" do
    sign_in @coordenador
    get :list, { :allocation_tags_ids => "#{allocation_tags(:al5).id}", :what_was_selected => [false, true, false, false] }
    assert_response :success
    assert_not_nil assigns(:allocation_tags_ids)
  end

  test "nao exibir cadastro de modulos e aulas para um usuario sem permissao" do
    sign_in users(:user2)

    get :list, { :allocation_tags_ids => "#{allocation_tags(:al5).id}", :what_was_selected => [false, true, false, false] }
    assert_response :error
  end

  ##
  # Ordenacao
  ##

  test 'mudar ordem das aulas 1 e 2' do
    assert_routing({ method: :put, path: change_order_lesson_path(1, 2) }, { controller: 'lessons', action: 'order', id: '1', change_id: '2' })

    assert_equal Lesson.find(1,2).map(&:order), [1,2] # verificacao da ordem antes da mudanca
    put :order, { id: 1, change_id: 2 }
    assert_equal Lesson.find(1,2).map(&:order), [2,1] # verificacao da ordem depois da mudanca
  end

  test 'nao mudar ordem de aulas privadas de outro dono' do
    assert_routing({ method: :put, path: change_order_lesson_path(7, 10) }, { controller: 'lessons', action: 'order', id: '7', change_id: '10' })

    assert_equal Lesson.find(7,10).map(&:order), [7,10] # verificacao da ordem antes da mudanca
    put :order, { id: 7, change_id: 10 }
    assert_response :unauthorized
    assert_equal Lesson.find(7,10).map(&:order), [7,10] # verificacao da ordem depois da mudanca
  end

  test 'mudar ordem de proprias aulas privadas' do
    assert_routing({ method: :put, path: change_order_lesson_path(7, 8) }, { controller: 'lessons', action: 'order', id: '7', change_id: '8' })

    assert_equal Lesson.find(7,8).map(&:order), [7,8] # verificacao da ordem antes da mudanca
    put :order, { id: 7, change_id: 8 }
    assert_response :success
    assert_equal Lesson.find(7,8).map(&:order), [8,7] # verificacao da ordem depois da mudanca
  end

  ##
  # Status
  ##

  test "liberar aula" do
    lesson = Lesson.find(lessons(:pag_index).id)
    FileUtils.touch(lesson.path(true).to_s)

    assert lesson.is_draft?

    put :change_status, {id: lesson.id, status: Lesson_Approved, allocation_tags_ids: "#{allocation_tags(:al6).id}", format: :json}
    assert_response :success

    assert_equal Lesson_Approved, Lesson.find(lessons(:pag_index).id).status
    FileUtils.rm_rf(lesson.path(true).to_s)
  end

  test "nao liberar aula sem arquivo inicial" do
    lesson = Lesson.find(lessons(:pag_index).id)
    assert lesson.is_draft?

    FileUtils.rm_rf(lesson.path(true).to_s)

    put :change_status, {id: lesson.id, status: Lesson_Approved, allocation_tags_ids: "#{allocation_tags(:al6).id}", format: :json}
    assert_response :unprocessable_entity

    assert_equal Lesson_Test, Lesson.find(lessons(:pag_index).id).status
  end


  test "setar aula como rascunho" do
    assert_routing({method: :put, path: change_status_lesson_path(lessons(:pag_virtual).id, Lesson_Approved)}, { controller: "lessons", action: "change_status", id: "#{lessons(:pag_virtual).id}", status: "#{Lesson_Approved}" })

    lesson = Lesson.find(lessons(:pag_virtual).id)
    assert_equal Lesson_Approved, lesson.status

    put :change_status, {id: lesson.id, status: Lesson_Test, allocation_tags_ids: "#{allocation_tags(:al6).id}", format: :json}
    assert_response :success

    assert_equal Lesson_Test, Lesson.find(lessons(:pag_virtual).id).status
  end

  test "liberar aula - professor" do
    sign_in @professor
    lesson = Lesson.find(lessons(:pag_index).id)
    FileUtils.touch(lesson.path(true).to_s)

    assert lesson.is_draft?

    put :change_status, {id: lesson.id, status: Lesson_Approved, allocation_tags_ids: "#{allocation_tags(:al6).id}", responsible: true, format: :js}
    assert_response :success

    assert_equal Lesson_Approved, Lesson.find(lessons(:pag_index).id).status
    FileUtils.rm_rf(lesson.path(true).to_s)
  end

  test "nao liberar aula - professor sem acesso" do
    sign_in users(:user)
    lesson = Lesson.find(lessons(:pag_index).id)
    FileUtils.touch(lesson.path(true).to_s)

    assert lesson.is_draft?

    put :change_status, {id: lesson.id, status: Lesson_Approved, allocation_tags_ids: "#{allocation_tags(:al6).id}", responsible: true, format: :js}
    assert_response :success

    assert_equal "flash_message('#{I18n.t(:no_permission)}', 'alert');", @response.body

    assert_equal Lesson_Test, Lesson.find(lessons(:pag_index).id).status
    FileUtils.rm_rf(lesson.path(true).to_s)
  end

  ##
  # Alterar módulo da aula
  ##

  test "alterar modulo da aula" do
    assert_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: "#{allocation_tags(:al6).id}", move_to_module: lesson_modules(:module5).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :success
  end

  test "nao alterar modulo da aula - sem acesso" do
    sign_in users(:coorddisc)
    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count") do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count") do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: "#{allocation_tags(:al10).id} #{allocation_tags(:al5).id}", move_to_module: lesson_modules(:module8).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :unprocessable_entity
  end

  test "nao alterar modulo da aula - sem permissao" do
    sign_in @professor
    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: "#{allocation_tags(:al6).id}", move_to_module: lesson_modules(:module5).id, lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :unprocessable_entity
  end

  test "nao alterar modulo da aula - dados invalidos" do
    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: "#{allocation_tags(:al6).id}", lessons_ids: [lessons(:pag_ufc).id, lessons(:pag_uol).id], format: "json"}
      end
    end

    assert_response :unprocessable_entity

    assert_no_difference("LessonModule.find(#{lesson_modules(:module5).id}).lessons.count", +2) do
      assert_no_difference("LessonModule.find(#{lesson_modules(:module1).id}).lessons.count", -2) do
        put :change_module, {id: lesson_modules(:module1).id, allocation_tags_ids: "#{allocation_tags(:al6).id}", move_to_module: lesson_modules(:module5).id, format: "json"}
      end
    end

    assert_response :unprocessable_entity
  end

  # test 'nao mudar modulo de aula privada de outro dono' do
  #   assert_no_difference("LessonModule.find(#{lesson_modules(:module2).id}).lessons.count") do
  #     assert_no_difference("LessonModule.find(#{lesson_modules(:module3).id}).lessons.count", -1) do
  #       put :change_module, {move_to_module: lesson_modules(:module2).id, allocation_tags_ids: "#{allocation_tags(:al6).id}", lessons_ids: [lessons(:lesson_with_files).id], format: "json"}
  #     end
  #   end

  #   assert_response :unprocessable_entity
  # end

  # test 'mudar ordem de proprias aulas privadas' do
  #   assert_routing({ method: :put, path: change_order_lesson_path(7, 8) }, { controller: 'lessons', action: 'order', id: '7', change_id: '8' })

  #   assert_equal Lesson.find(7,8).map(&:order), [7,8] # verificacao da ordem antes da mudanca
  #   put :order, { id: 7, change_id: 8 }
  #   assert_response :success
  #   assert_equal Lesson.find(7,8).map(&:order), [8,7] # verificacao da ordem depois da mudanca
  # end

  ## Importação

  test 'importar minha aula privada - arquivo' do
    assert_difference('Lesson.count') do
      put :import, { lessons: "#{5}, #{1}, #{Date.today},,true", allocation_tags_ids: [allocation_tags(:al2).id] }
    end

    assert_response :success
  end

  test 'importar aula publica - link' do
    assert_difference('Lesson.count') do
      put :import, { lessons: "#{6}, #{1}, #{Date.today},,true", allocation_tags_ids: [allocation_tags(:al2).id] }
    end

    assert_response :success
  end

  test 'nao deve importar aula rascunho' do
    assert_no_difference('Lesson.count') do
      put :import, { lessons: "#{7}, #{1}, #{Date.today},,true", allocation_tags_ids: [allocation_tags(:al2).id] }
    end

    assert_response :unprocessable_entity
  end

  test 'nao deve importar aula de outro dono' do
    assert_no_difference('Lesson.count') do
      put :import, { lessons: "#{10}, #{1}, #{Date.today},,true", allocation_tags_ids: [allocation_tags(:al2).id] }
    end

    assert_response :unauthorized
  end

  test 'nao deve importar aula sem aula' do
    assert_no_difference('Lesson.count') do
      put :import, { allocation_tags_ids: [allocation_tags(:al2).id] }
    end

    assert_response :unprocessable_entity
  end

  test 'nao deve importar aula sem acesso' do
    assert_no_difference('Lesson.count') do
      put :import, { lessons: "#{7}, #{1}, #{Date.today},,true", allocation_tags_ids: [allocation_tags(:al10).id] }
    end

    assert_response :unauthorized
  end

  test 'nao deve importar aula sem data ou com data invalida' do
    assert_no_difference('Lesson.count') do
      put :import, { lessons: "#{7}, #{1},,,true", allocation_tags_ids: [allocation_tags(:al2).id] }
    end
    assert_response :unprocessable_entity

    assert_no_difference('Lesson.count') do
      put :import, { lessons: "#{7}, #{1},#{Date.today+1.day},#{Date.today},true", allocation_tags_ids: [allocation_tags(:al2).id] }
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
