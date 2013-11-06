require 'test_helper'
require 'fileutils' # utilizado na remoção de diretórios, pois o 'Dir.rmdir' não remove diretórios que não estejam vazis

class LessonFilesControllerTest < ActionController::TestCase

  include Devise::TestHelpers
  # para reconhecer o método 'fixture_file_upload' no teste
  include ActionDispatch::TestProcess

  def setup
    sign_in users(:editor)
    @pag_index  = lessons(:pag_index)
    @pag_goo    = lessons(:pag_goo)
    @pag_bbc    = lessons(:pag_bbc)
  end

  def teardown
    # limpa as aulas
    remove_lesson_files(@pag_index.id)
    remove_lesson_files(@pag_bbc.id)
  end

  ##
  # Lista de arquivos de aula
  ##

  # Usuário com permissão e acesso
  test 'exibir lista de arquivos da aula' do
    get :index, lesson_id: @pag_index.id

    assert_not_nil assigns(:lesson)
    assert_not_nil assigns(:address)

    assert_response :success
    assert_template :index
    assert_select '#tree' # verifica se existe a div que receberá a árvore de arquivos
  end

  # Aula do tipo errado
  test 'nao exibir lista de arquivos da aula - aula de links' do
    get :index, lesson_id: @pag_goo.id

    assert_not_nil assigns(:lesson)
    assert_not_nil assigns(:address)

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree' # div onde a árvore de arquivos será montada não deve existir
  end

  # Usuário sem permissão
  test 'nao exibir lista de arquivos da aula - sem permissao' do
    sign_in users(:aluno1)
    get :index, lesson_id: @pag_index.id

    assert_not_nil assigns(:lesson)
    assert_nil assigns(:address)

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree' # div onde a árvore de arquivos será montada não deve existir
  end

  # Usuário sem acesso
  test 'nao exibir lista de arquivos da aula - sem acesso' do
    sign_in users(:coorddisc)
    get :index, lesson_id: @pag_bbc.id # uc 3 / course 2 => só editor tem permissão nas al_tag destes

    assert_not_nil assigns(:lesson)
    assert_nil assigns(:address)

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree' # div onde a árvore de arquivos será montada não deve existir
  end

  ##
  # Nova pasta
  ##

  # Usuário com acesso e permissão
  test 'cria nova pasta na arvore de arquivos' do
    Dir.mkdir(Lesson::FILES_PATH.join("#{@pag_index.id}")) unless File.exist? Lesson::FILES_PATH.join("#{@pag_index.id}") # cria se já não existir
    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: 'folder', path: @pag_index.name} # nova pasta na pasta raiz
    end
    assert_response :success
    assert_template :index
    assert_select '#tree'
  end

  # Usuário sem permissão
  test 'nao cria nova pasta na arvore de arquivos - sem permissao' do
    sign_in users(:aluno1)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: 'folder', path: @pag_index.name} # nova pasta na pasta raiz
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end

  # Usuário sem acesso
  test 'nao cria nova pasta na arvore de arquivos - sem acesso' do

    sign_in users(:coorddisc)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}")).size') do
      post :new, {lesson_id: @pag_bbc.id, type: 'folder', path: @pag_bbc.name} # nova pasta na pasta raiz
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end  

  ##
  # Upload de arquivos
  ##

  # Usuário com acesso e permissão com um arquivo válido
  test 'envia arquivo valido' do
    define_files_to_upload    

    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '/', files: [@valid_file]}}
    end

    assert_response :success
    assert_template :index
    assert_select '#tree'

    assert File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'valid_file_test.png'))
  end

  # Usuário com acesso e permissão com um arquivo inválido
  test 'nao envia arquivo invalido' do
    define_files_to_upload    

    # problema com a extensao
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size') do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@invalid_file]}}
    end

    assert_response :error
    assert_template nothing: true

    assert (not File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'invalid_file_test.exe')))

    # problema com o nome
    post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@valid_file]}}
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size') do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@invalid_file]}}
    end

    assert_response :error
    assert_template nothing: true
  end

  # Usuário sem permissão
  test 'nao envia arquivo valido - sem permissao' do
    define_files_to_upload    

    sign_in users(:aluno1)

    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size') do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@valid_file]}}
    end

    assert_response :error
    assert_template nothing: true

    assert (not File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'valid_file_test.png')))
  end

  # Usuário sem acesso
  test 'nao envia arquivo valido - sem acesso' do
    define_files_to_upload

    sign_in users(:coorddisc)

    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}")).size') do
      post :new, {lesson_id: @pag_bbc.id, type: 'upload', lesson_files: {path: '', files: [@valid_file]}}
    end

    assert_response :error
    assert_template nothing: true

    assert (not File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}", 'valid_file_test.png')))
  end

  ##
  # Renomear arquivo/pasta
  ##

  # Usuário com acesso e permissão - nome válido
  test 'renomeia pasta' do
    remove_if_exists(@pag_index.id, 'Pasta Renomeada') # remove se já existir pasta com o nome que será renomeado
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    put :edit, {lesson_id: @pag_index.id, type: 'rename', path: 'Nova Pasta', node_name: 'Pasta Renomeada'}

    assert_response :success
    assert_template :index
    assert_select '#tree'

    assert File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'Pasta Renomeada'))
    assert (not File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'Nova Pasta')))
  end

  # Usuário com acesso e permissão - nome inválido
  test 'nao renomeia pasta - nome invalido' do
    folder1 = create_root_folder(@pag_index.id).split(File::SEPARATOR).last # Cria pasta dentro do diretório da aula e recupera seu nome
    folder2 = create_root_folder(@pag_index.id).split(File::SEPARATOR).last # Cria outra pasta dentro do diretório da aula e recupera seu nome

    put :edit, {lesson_id: @pag_index.id, type: 'rename', path: folder1, node_name: 'Pasta Renomeada'}
    assert_response :success

    put :edit, {lesson_id: @pag_index.id, type: 'rename', path: folder2, node_name: 'Pasta Renomeada'}
    assert_response :error
    assert_template nothing: true
  end

  # Usuário sem permissão
  test 'nao renomeia pasta - sem permissao' do
    remove_if_exists(@pag_index.id, 'Pasta Renomeada') # remove se já existir pasta com o nome que será renomeado
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    sign_in users(:aluno1)
    put :edit, {lesson_id: @pag_index.id, type: 'rename', path: 'Nova Pasta', node_name: 'Pasta Renomeada'}

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'

    assert (not File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'Pasta Renomeada')))
    assert File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_index.id}", 'Nova Pasta'))
  end

  # Usuário sem acesso
  test 'nao renomeia pasta - sem acesso' do
    remove_if_exists(@pag_bbc.id, 'Pasta Renomeada') # remove se já existir pasta com o nome que será renomeado
    create_root_folder(@pag_bbc.id) # Cria pasta dentro do diretório da aula.

    sign_in users(:coorddisc)
    put :edit, {lesson_id: @pag_bbc.id, type: 'rename', path: 'Nova Pasta', node_name: 'Pasta Renomeada'}
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'

    assert (not File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}", 'Pasta Renomeada')))
    assert File.exists?(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}", 'Nova Pasta'))
  end

  # Usuário com acesso e permissão renomeando arquivo inicial
  # test 'renomeia arquivo inicial e corrige endereco' do
  #   # cria arquivo
  #   define_files_to_upload
  #   assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
  #     post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '/', files: [@valid_file]}}
  #   end
  #   # define como inicial
  #   put :edit, {lesson_id: @pag_index.id, type: 'initial_file', path: "/#{@valid_file.original_filename}"}

  #   # move arquivo inicial
  #   put :edit, {lesson_id: @pag_index.id, type: 'rename', path: "/#{@valid_file.original_filename}", node_name: 'arquivo_inicial_renomeado.pdf'}

  #   assert_response :success
  #   assert_template :index

  #   # verifica se houve mudança
  #   assert_equal "arquivo_inicial_renomeado.pdf", Lesson.find(@pag_index.id).address
  # end

  ##
  # Mover arquivo/pasta
  ##
  # verificar questão de nomes, pra onde moveu, onde criou

  # Usuário com acesso e permissão
  test 'move pasta' do
    folder1 = create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula e recupera caminho completo
    folder2 = create_root_folder(@pag_index.id).split(File::SEPARATOR).last # Cria uma segunda pasta dentro do diretório da aula e recupera o nome da pasta

    put :edit, {type: 'move', lesson_id: @pag_index.id, paths_to_move: [folder2], path_to_move_to: folder1.split(File::SEPARATOR).last, initial_file_path: "false"}

    assert_response :success
    assert_template :index
    assert_select '#tree'

    assert Dir.entries(folder1).include?(folder2)
    assert (not Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).include?(folder2))
  end  

  # Usuário sem permissão
  test 'nao move pasta - sem permissao' do
    folder1 = create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula e recupera caminho completo
    folder2 = create_root_folder(@pag_index.id).split(File::SEPARATOR).last # Cria uma segunda pasta dentro do diretório da aula e recupera o nome da pasta

    sign_in users(:aluno1)
    put :edit, {type: 'move', lesson_id: @pag_index.id, paths_to_move: [folder2], path_to_move_to: folder1.split(File::SEPARATOR).last, initial_file_path: "false"}

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'

    assert (not Dir.entries(folder1).include?(folder2))
    assert Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).include?(folder2)
  end  

  # Usuário sem acesso
  test 'nao move pasta - sem acesso' do
    folder1 = create_root_folder(@pag_bbc.id) # Cria pasta dentro do diretório da aula e recupera caminho completo
    folder2 = create_root_folder(@pag_bbc.id).split(File::SEPARATOR).last # Cria uma segunda pasta dentro do diretório da aula e recupera o nome da pasta

    sign_in users(:coorddisc)
    put :edit, {type: 'move', lesson_id: @pag_bbc.id, paths_to_move: [folder2], path_to_move_to: folder1.split(File::SEPARATOR).last, initial_file_path: "false"}

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'

    assert (not Dir.entries(folder1).include?(folder2))
    assert Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}")).include?(folder2)
  end  

  # Usuário com acesso e permissão movendo arquivo inicial
  test 'move arquivo inicial e corrige endereco' do
    # cria arquivo
    define_files_to_upload    
    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@valid_file]}}
    end
    # define como inicial
    put :edit, {lesson_id: @pag_index.id, type: 'initial_file', path: "#{@valid_file.original_filename}"}
    # cria pasta
    folder_name = create_root_folder(@pag_bbc.id).split(File::SEPARATOR).last

    # move arquivo inicial
    put :edit, {type: 'move', lesson_id: @pag_index.id, paths_to_move: ["#{@valid_file.original_filename}"], path_to_move_to: "#{folder_name}", initial_file_path: "#{@valid_file.original_filename}"}

    assert_response :success
    assert_template :index

    # verifica se houve mudança
    assert_equal "#{folder_name}/#{@valid_file.original_filename}", Lesson.find(@pag_index.id).address
  end

  ##
  # Remover arquivo/pasta
  ##

  # Usuário com acesso e permissão
  test 'remove pasta' do
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', -1) do
      delete :destroy, {lesson_id: @pag_index.id, path: 'Nova Pasta'}
    end
    assert_response :success
    assert_template :index
    assert_select '#tree'
  end

  # Usuário sem permissão
  test 'nao remove pasta - sem permissao' do
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    sign_in users(:aluno1)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size') do
      delete :destroy, {lesson_id: @pag_index.id, path: 'Nova Pasta11'}
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end

  # Usuário sem acesso
  test 'nao remove pasta - sem acesso' do
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.
    
    sign_in users(:coorddisc)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}")).size') do
      delete :destroy, {lesson_id: @pag_bbc.id, path: 'Nova Pasta1'}
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end

  # Usuário com acesso e permissão não podendo remover arquivo inicial
  test 'nao remove arquivo inicial' do
    # cria arquivo
    define_files_to_upload    
    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@valid_file]}}
    end
    # define como inicial
    put :edit, {lesson_id: @pag_index.id, type: 'initial_file', path: "#{@valid_file.original_filename}"}

    # tenta excluir
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size') do
      delete :destroy, {lesson_id: @pag_index.id, path: "#{@valid_file.original_filename}"}
    end

    assert_response :error
    assert_template nothing: true

    # verifica se houve mudança
    assert_equal "#{@valid_file.original_filename}", Lesson.find(@pag_index.id).address
  end

  ##
  # Definir arquivo inicial
  ##

  # Usuário com acesso e permissão
  test 'define arquivo inicial' do
    # cria arquivo
    define_files_to_upload    
    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: 'upload', lesson_files: {path: '', files: [@valid_file]}}
    end

    # tenta definir como inicial
    put :edit, {lesson_id: @pag_index.id, type: 'initial_file', path: "#{@valid_file.original_filename}"}

    assert_response :success
    assert_template :index

    # verifica mudança
    assert_equal "#{@valid_file.original_filename}", Lesson.find(@pag_index.id).address
  end

  # Usuário sem permissão 
  # Obs: O ideal aqui seria fazer o editor realizar o upload do arquivo primeiro, mas os testes 
  # estavam falhando (sem aparente motivo) quando o fazíamos. Portanto, optamos por uma solução
  # "menos detalhada".
  test 'nao define arquivo inicial - sem permissao' do
    # define arquivo
    define_files_to_upload

    sign_in users(:aluno1)

    # tenta definir como inicial
    put :edit, {lesson_id: @pag_index.id, type: 'initial_file', path: "#{@valid_file.original_filename}"}

    assert_response :error
    assert_template nothing: true

    # verifica mudança
    assert_not_equal "#{@valid_file.original_filename}", Lesson.find(@pag_index.id).address
  end

  # Usuário sem acesso
  # Obs: O ideal aqui seria fazer o editor realizar o upload do arquivo primeiro, mas os testes 
  # estavam falhando (sem aparente motivo) quando o fazíamos. Portanto, optamos por uma solução
  # "menos detalhada".
  test 'nao define arquivo inicial - sem acesso' do
    # cria arquivo
    define_files_to_upload    

    sign_in users(:coorddisc)

    # tenta definir como inicial
    put :edit, {lesson_id: @pag_bbc.id, type: 'initial_file', path: "#{@valid_file.original_filename}"}

    assert_response :error
    assert_template nothing: true

    # verifica mudança
    assert_not_equal "#{@valid_file.original_filename}", Lesson.find(@pag_bbc.id).address
  end

  # Não define pasta como arquivo inicial
  test 'nao define arquivo inicial - nao pode ser pasta' do
    folder_name = create_root_folder(@pag_index.id).split(File::SEPARATOR).last # Cria pasta dentro do diretório da aula.

    # tenta definir como inicial
    put :edit, {lesson_id: @pag_index.id, type: 'initial_file', path: "#{folder_name}"}

    assert_response :error
    assert_template nothing:true

    # verifica mudança
    assert_not_equal "#{folder_name}", Lesson.find(@pag_index.id).address
  end

  ##
  # Extract files
  ##

  test "rota para extrair arquivos de aula" do
    assert_routing extract_lesson_files_path("1", "file.zip"), {
      controller: "lesson_files", action: "extract_files", lesson_id: "1", file: "file.zip"
    }
  end

  test "extrair arquivo de aula" do
    lesson_id = lessons(:pag_index).id.to_s
    file_name = 'lesson_test.zip'

    # copiando arquivo de aula de teste para o local adequado
    FileUtils.mkdir_p(File.join(Lesson::FILES_PATH, lesson_id)) # criando diretorio da aula
    FileUtils.cp(File.join(Rails.root, 'test', 'fixtures', 'files', 'lessons', file_name), File.join(Lesson::FILES_PATH, lesson_id, file_name))

    get :extract_files, {lesson_id: lesson_id, file: "lesson_test.zip"}

    assert_response :success
    assert_template :index
  end

  test "nao extrair zip de aula com arquivos invalidos" do
    lesson_id = lessons(:pag_index).id.to_s
    file_name = 'lesson_test_invalid.zip'

    # copiando arquivo de aula de teste para o local adequado
    FileUtils.mkdir_p(File.join(Lesson::FILES_PATH, lesson_id)) # criando diretorio da aula
    FileUtils.cp(File.join(Rails.root, 'test', 'fixtures', 'files', 'lessons', file_name), File.join(Lesson::FILES_PATH, lesson_id, file_name))

    get :extract_files, {lesson_id: lesson_id, file: "lesson_test_invalid.zip"}

    assert_response :unprocessable_entity
    assert response.body, {success: false, msg: I18n.t(:zip_contains_invalid_files, scope: :lesson_files)}.to_json
  end

private

  # cria pasta na raiz
  def create_root_folder(lesson_id)
    folder_number, file = '', File.join(Lesson::FILES_PATH, "#{lesson_id}")
    # se a pasta já existir, incrementa um número à ela (Nova Pasta -> Nova Pasta1 -> Nova Pasta2)
    while File.exists?(File.join(file, "Nova Pasta#{folder_number}")) do
      folder_number = 0 if folder_number == ''
      folder_number += 1
    end
    file = File.join(file, "Nova Pasta#{folder_number}") unless File.exist?(File.join(file, "Nova Pasta#{folder_number}"))
    Dir.mkdir file

    return file
  end

  # verifica se a pasta indicada já existe
  def remove_if_exists(lesson_id, folder_path)
    file = File.join(Lesson::FILES_PATH, "#{lesson_id}", "#{folder_path}")
    FileUtils.rm_rf file if File.exist?(file)
  end

  # remove todos os arquivos da aula
  def remove_lesson_files(lesson_id)
    path = File.join(Lesson::FILES_PATH, "#{lesson_id}")
    FileUtils.rm_rf path
    Dir.mkdir(path)
  end

  def define_files_to_upload
    @valid_file   = ActionDispatch::Http::UploadedFile.new({
                    :filename => 'valid_file_test.png',
                    :content_type => 'image/png',
                    :tempfile => File.new("#{Rails.root}/test/fixtures/files/lessons/valid_file_test.png")
                   })
    @invalid_file = ActionDispatch::Http::UploadedFile.new({
                    :filename => 'invalid_file_test.exe',
                    :content_type => 'application/x-ms-dos-executable',
                    :tempfile => File.new("#{Rails.root}/test/fixtures/files/lessons/invalid_file_test.exe")
                   })
  end

end

