require 'test_helper'
require 'fileutils' # utilizado na remoção de diretórios, pois o "Dir.rmdir" não remove diretórios que não estejam vazis

class LessonFilesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
    @pag_index = lessons(:pag_index)
    @pag_goo   = lessons(:pag_goo)
    @pag_bbc   = lessons(:pag_bbc)
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
    assert_response :success
    assert_template :index
    assert_select '#tree' # verifica se existe a div que receberá a árvore de arquivos

    # raise @response.body # ele não monta a árvore... mas tem dados
    # assert_select'ul'
    # assert_select "a.dynatree-title", lessons(:pag_index).name # verifica se existe a pasta raiz com o nome da aula
    # assert_select 'btn-new-folder' # verifica se existe a pasta raiz com o nome da aula
  end

  # Aula do tipo errado
  test 'nao exibir lista de arquivos da aula - aula de links' do
    get :index, lesson_id: @pag_goo.id
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree' # div onde a árvore de arquivos será montada não deve existir
  end

  # Usuário sem permissão
  test 'nao exibir lista de arquivos da aula - sem permissao' do
    sign_in users(:aluno1)
    get :index, lesson_id: @pag_index.id
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree' # div onde a árvore de arquivos será montada não deve existir
  end

  # Usuário sem acesso
  test 'nao exibir lista de arquivos da aula - sem acesso' do
    sign_in users(:coorddisc)
    get :index, lesson_id: @pag_bbc.id # uc 3 / course 2 => só editor tem permissão nas al_tag destes
    assert_response :error
    assert_nil assigns(:files)
    assert_nil assigns(:folders)
    assert_template nothing: true
    assert_no_tag '#tree' # div onde a árvore de arquivos será montada não deve existir
  end

  ##
  # Nova pasta
  ##

  # Usuário com acesso e permissão
  test 'cria nova pasta na arvore de arquivos' do
    verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.

    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: "folder", path: "/"+@pag_index.name} # nova pasta na pasta raiz
    end
    assert_response :success
    assert_template :index
    assert_select '#tree'
  end

  # Usuário sem permissão
  test 'nao cria nova pasta na arvore de arquivos - sem permissao' do
    verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.

    sign_in users(:aluno1)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', +1) do
      post :new, {lesson_id: @pag_index.id, type: "folder", path: "/"+@pag_index.name} # nova pasta na pasta raiz
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end

  # Usuário sem acesso
  test 'nao cria nova pasta na arvore de arquivos - sem acesso' do
    verify_lesson_dir(@pag_bbc.id) # Verifica se o diretório existe. Se não, cria.

    sign_in users(:coorddisc)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}")).size') do
      post :new, {lesson_id: @pag_bbc.id, type: "folder", path: "/"+@pag_bbc.name} # nova pasta na pasta raiz
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end  

  ##
  # Upload de arquivos
  ##

  # Usuário com acesso e permissão

  # Usuário sem permissão

  # Usuário sem acesso

  ##
  # Renomear arquivo/pasta
  ##

  # Usuário com acesso e permissão
  test 'renomeia pasta' do
    verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.
    remove_if_exists(@pag_index.id, "Pasta Renomeada") # remove se já existir pasta com o nome que será renomeado
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    put :edit, {lesson_id: @pag_index.id, type: "rename", path: "Nova Pasta", node_name: "Pasta Renomeada"}

    assert_response :success
    assert_template :index
    assert_select '#tree'

    assert File.exists?(File.join("#{Rails.root}", "media", "lessons", "#{@pag_index.id}", "Pasta Renomeada"))
    assert (not File.exists?(File.join("#{Rails.root}", "media", "lessons", "#{@pag_index.id}", "Nova Pasta")))
  end

  # Usuário sem permissão
  test 'nao renomeia pasta - sem permissao' do
    verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.
    remove_if_exists(@pag_index.id, "Pasta Renomeada") # remove se já existir pasta com o nome que será renomeado
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    sign_in users(:aluno1)
    put :edit, {lesson_id: @pag_index.id, type: "rename", path: "Nova Pasta", node_name: "Pasta Renomeada"}

    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'

    assert (not File.exists?(File.join("#{Rails.root}", "media", "lessons", "#{@pag_index.id}", "Pasta Renomeada")))
    assert File.exists?(File.join("#{Rails.root}", "media", "lessons", "#{@pag_index.id}", "Nova Pasta"))
  end

  # Usuário sem acesso
  test 'nao renomeia pasta - sem acesso' do
    verify_lesson_dir(@pag_bbc.id) # Verifica se o diretório existe. Se não, cria.
    remove_if_exists(@pag_bbc.id, "Pasta Renomeada") # remove se já existir pasta com o nome que será renomeado
    create_root_folder(@pag_bbc.id) # Cria pasta dentro do diretório da aula.

    sign_in users(:coorddisc)
    put :edit, {lesson_id: @pag_bbc.id, type: "rename", path: "Nova Pasta", node_name: "Pasta Renomeada"}
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'

    assert (not File.exists?(File.join("#{Rails.root}", "media", "lessons", "#{@pag_bbc.id}", "Pasta Renomeada")))
    assert File.exists?(File.join("#{Rails.root}", "media", "lessons", "#{@pag_bbc.id}", "Nova Pasta"))
  end

  ##
  # Mover arquivo/pasta
  ##
  # verificar questão de nomes, pra onde moveu, onde criou

  # Usuário com acesso e permissão
  test 'move pasta' do
    # verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.
    
    # folder1 = create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.
    # folder2 = create_root_folder(@pag_index.id) # Cria uma segunda pasta dentro do diretório da aula.

    # put :edit, {type: "move", lesson_id: @pag_index.id, paths_to_move: [folder2], path_to_move_to: folder1}

    # # raise "#{Dir.entries(folder1)}"
    # assert Dir.entries(folder1).include?(folder2.split(File::SEPARATOR).last)

    # assert_response :success
    # assert_template :index
    # assert_select '#tree'
  end  

  # Usuário sem permissão

  # Usuário sem acesso

  ##
  # Remover arquivo/pasta
  ##

  # Usuário com acesso e permissão
  test 'remove pasta' do
    verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    assert_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size', -1) do
      delete :destroy, {lesson_id: @pag_index.id, path: "/Nova Pasta"}
    end
    assert_response :success
    assert_template :index
    assert_select '#tree'
  end

  # Usuário sem permissão
  test 'nao remove pasta - sem permissao' do
    verify_lesson_dir(@pag_index.id) # Verifica se o diretório existe. Se não, cria.
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.

    sign_in users(:aluno1)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_index.id}")).size') do
      delete :destroy, {lesson_id: @pag_index.id, path: "/Nova Pasta11"}
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end

  # Usuário sem acesso
  test 'nao remove pasta - sem acesso' do
    verify_lesson_dir(@pag_bbc.id) # Verifica se o diretório existe. Se não, cria.
    create_root_folder(@pag_index.id) # Cria pasta dentro do diretório da aula.
    
    sign_in users(:coorddisc)
    assert_no_difference('Dir.entries(File.join(Lesson::FILES_PATH, "#{@pag_bbc.id}")).size') do
      delete :destroy, {lesson_id: @pag_bbc.id, path: "/Nova Pasta1"}
    end
    assert_response :error
    assert_template nothing: true
    assert_no_tag '#tree'
  end

private
  # Verifica se a aula já tem um diretório. Caso não, cria.
  # em uma situação real, o usuário sempre acessa a listagem antes. 
  # Lá que é feita esta verificação.
  def verify_lesson_dir(lesson_id)
    file = File.join(Lesson::FILES_PATH, "#{lesson_id}")
    Dir.mkdir(file) unless File.exist?(file)
  end

  # cria pasta na raiz
  def create_root_folder(lesson_id)
    folder_number, file = "", File.join(Lesson::FILES_PATH, "#{lesson_id}")
    # Se a pasta já existir, incrementa um número à ela (Nova Pasta -> Nova Pasta1 -> Nova Pasta2)
    while File.exists?(File.join(file, "Nova Pasta#{folder_number}")) do
      folder_number = 0 if folder_number == ""
      folder_number += 1
    end
    file = File.join(file, "Nova Pasta#{folder_number}") unless File.exist?(File.join(file, "Nova Pasta#{folder_number}"))
    Dir.mkdir file

    return file
  end

  def remove_if_exists(lesson_id, folder_path)
    file = File.join(Lesson::FILES_PATH, "#{lesson_id}", "#{folder_path}")
    FileUtils.rm_rf file if File.exist?(file)
  end

  def remove_lesson_files(lesson_id)
    path = File.join(Lesson::FILES_PATH, "#{lesson_id}")
    FileUtils.rm_rf path
    Dir.mkdir(path)
  end


end

