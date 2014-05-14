require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :sent_assignments

  # Aluno
  test 'nao permitir upload de arquivo enviado pelo aluno por usuario com permissao e sem acesso' do
    sign_in(users(:aluno1))
    post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
  end

  # Grupo
  test 'nao permitir upload de arquivo enviado pelo grupo por usuario com permissao e sem acesso' do
    sign_in(users(:aluno2))
    post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
  end

  # Aluno
  test 'nao permitir upload de arquivo enviado pelo aluno por usuario sem permissao' do
    sign_in(users(:coorddisc))
    post :upload_file, {:assignment_id => assignments(:a7), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Grupo
  test 'nao permitir upload de arquivo enviado pelo grupo por usuario sem permissao' do
    sign_in(users(:coorddisc))
    post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil com permissao
  test "permitir acessar pagina de upload de arquivos publicos para usuario com permissao" do
    sign_in(users(:aluno1))
    get :send_public_files_page
    assert_response :success
    assert_template :send_public_files_page
  end

  # Perfil sem permissao
  test "nao permitir acessar pagina de upload de arquivos publicos para usuario sem permissao" do
    sign_in(users(:coorddisc))
    get :send_public_files_page
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

end
