require 'test_helper'

class AdministrationsControllerTest < ActionDispatch::IntegrationTest
  
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  def setup
    @admin  = users(:admin)
    @editor = users(:editor)
    @aluno1 = users(:aluno1)
    login(@admin)
    get home_path # acessa a home do usuário antes de qualquer ação
  end

  test "acessar pagina de administracao de usuario" do
    get admin_users_path
    assert_response :success
  end

  test "nao acessar administracao de usuario sem permissao" do 
    login(@editor)
    get admin_users_path
    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "buscar usuario" do
    get search_admin_users_path, user: 'aluno 1', type_search: 'name'
    assert_not_nil assigns(:users)
    assert_equal users(:aluno1).name, assigns(:users).first.name
  end

  test "nao buscar usuario sem permissao" do 
    login(@editor)
    get search_admin_users_path, user: 'aluno 1', type_search: 'name'
    assert_nil assigns(:users)
    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "buscar usuario nao retorna dados" do
    get search_admin_users_path, user: 'aluno xyz', type_search: 'name'
    assert assigns(:users).empty?
  end

  test "editar usuario" do
    assert_no_difference(["User.count"]) do
      put "/admin/users/#{@aluno1.id}", { data: {name: "aluno1 alterado"}} 
    end

    assert_equal "aluno1 alterado", User.find(@aluno1.id).name
  end

  test "nao editar usuario sem permissao" do 
    login(@editor)
    
    assert_no_difference(["User.count"]) do
      put "/admin/users/#{@aluno1.id}", { data: { name: "aluno1 alterado", email: 'aluno1@solar.ufc.br'}}
    end
    assert_not_equal "aluno1 alterado", User.find(@aluno1.id).name

    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "editar status de alocacao de usuario" do
    allocation = allocations(:aluno3_al8)
    assert_no_difference(["Allocation.count"]) do
      put "/admin/allocations/#{allocation.id}", {status: Allocation_Cancelled}
    end

    assert_equal Allocation.find(allocation.id).status, Allocation_Cancelled
  end

  test "nao editar status de alocacao sem permissao" do 
    login(@editor)
    
    allocation = allocations(:aluno3_al8)
    assert_no_difference(["Allocation.count"]) do
      put "/admin/allocations/#{allocation.id}", {status: Allocation_Cancelled}
    end

    assert_not_equal Allocation.find(allocation.id).status, Allocation_Cancelled

    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "listar solicitacoes de perfis pendentes" do
    login(@admin)
    get allocation_approval_administrations_path
    assert_equal 2, assigns(:allocations).count

    login(@editor)
    get allocation_approval_administrations_path
    assert_equal 1, assigns(:allocations).count
  end

  test "nao listar solicitacoes de perfis pendentes" do
    login(users(:professor))
    get allocation_approval_administrations_path

    assert_nil assigns(:allocations)
    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "solicitar senha para usuario" do
    assert_difference("LogAction.find_all_by_log_type(6).count") do
      put "/admin/users/#{@editor.id}/password"
    end

    assert_response :success
  end

  ## import users

  test "importacao de users - acessar pagina inicial" do
    get import_users_filter_path
    assert_response :success
  end

  test "importacao de users - tentar enviar arquivo invalido" do
    # curso livre - turma IL-MAR
    assert_no_difference("User.count") do
      assert_no_difference("Allocation.count") do
        post import_users_batch_path, {
          allocation_tags_ids: "#{allocation_tags(:al37).id}",
          batch: {file: fixture_file_upload('files/import-users/invalid-header.csv')}
        }
      end
    end

    assert_equal get_json_response("alert"), I18n.t(:invalid_file, scope: [:administrations, :import_users])
  end

  test "importacao de users - importar users para uma turma e baixar log" do
    # curso livre - turma IL-MAR
    assert_difference("User.count", 3) do
      assert_difference("Allocation.count", 6) do
        post import_users_batch_path, {
          allocation_tags_ids: "#{allocation_tags(:al37).id}",
          batch: {file: fixture_file_upload('files/import-users/new.csv')}
        }
      end
    end

    assert_not_nil file = assigns(:log_file)

    get "/admin/import/users/log/#{file}"
    assert_response :success
  end

  test "importacao de users - importar users existentes para uma turma" do
    # curso livre - turma IL-MAR
    assert_difference("User.count", 3) do
      assert_difference("Allocation.count", 6) do
        post import_users_batch_path, {
          allocation_tags_ids: "#{allocation_tags(:al37).id}",
          batch: {file: fixture_file_upload('files/import-users/new.csv')}
        }
      end
    end

    # curso livre - turma IL-MAR
    assert_no_difference("User.count") do
      assert_no_difference("Allocation.count") do
        post import_users_batch_path, {
          allocation_tags_ids: "#{allocation_tags(:al37).id}",
          batch: {file: fixture_file_upload('files/import-users/existents.csv')}
        }
      end
    end

    # quimica I - QM-MAR
    assert_no_difference("User.count") do
      assert_difference("Allocation.count", 1) do
        post import_users_batch_path, {
          allocation_tags_ids: "#{allocation_tags(:al11).id}",
          batch: {file: fixture_file_upload('files/import-users/existents.csv')}
        }
      end
    end
  end

  test "acessar pagina de responsaveis" do
    get admin_responsibles_path curriculum_unit_type_id: 2, course_id: 2
    assert_response :success
  end

  test "nao acessar pagina de responsaveis sem permissao" do 
    login(@editor)
    get admin_responsibles_path curriculum_unit_type_id: 2, course_id: 2

    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

end
