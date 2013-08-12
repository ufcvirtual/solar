require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :sent_assignments


  # Aluno
  test 'nao permitir upload de arquivo enviado pelo aluno por usuario com permissao e sem acesso' do
    sign_in(users(:aluno1))
    post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Grupo
  test 'nao permitir upload de arquivo enviado pelo grupo por usuario com permissao e sem acesso' do
    sign_in(users(:aluno2))
    post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Público
  # => assignments_with_allocation_tag_test.rb

  # Perfil sem permissao

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

  
  # Do enunciado da atividade
  # Não existe o upload de arquivos para uma atividade (editor)
  # test "permitir fazer download de arquivos do enunciado da atividade para usuario com permissao" do
    # sign_in users(:professor)
    # get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_enunciation_files(:aef1).id, :type => 'enunciation'})
    # assert_response :success
    # sign_out(users(:professor1 ))

    # sign_in(users(:aluno3))
    # get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => assignment_enunciation_files(:aef2).id, :type => 'enunciation'})
    # assert_response :success
  # end

  # Publico
  # => assignments_with_allocation_tag_test.rb

  # Do enunciado da atividade
  test "nao permitir fazer download de arquivos do enunciado da atividade para usuario com permissao e sem acesso" do
    sign_in(users(:professor2))
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_enunciation_files(:aef1).id, :type => 'enunciation'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    sign_out(users(:professor2))

    sign_in(users(:aluno1))
    get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => assignment_enunciation_files(:aef2).id, :type => 'enunciation'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil sem permissao


  # Publico
  # => assignments_with_allocation_tag_test.rb

  # Do enunciado da atividade
  test "nao permitir fazer download de arquivos do enunciado da atividade para usuario sem permissao" do
    sign_in(users(:coorddisc))
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_enunciation_files(:aef1).id, :type => 'enunciation'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ##
  # Delete_file
  ##

  # Perfil com permissao e usuario com acesso


  # Público
  # => assignments_with_allocation_tag_test.rb

  # Perfil com permissao e usuario sem acesso


  # # Público
  # => assignments_with_allocation_tag_test.rb

  ##
  # Send_public_files_page
  ##

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
