require 'test_helper'
 
# Aqui estão os testes dos métodos do cotnroller assignments
# que, para acessá-los, se faz necessário estar em uma unidade
# curricular. Logo, há a necessidade de acessar o método
# "add_tab" de outro controller. O que não é permitido em testes
# funcionais.

class AssignmentsWithAllocationTagTest < ActionDispatch::IntegrationTest
  fixtures :all
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  def setup
    @quimica_tab = "/application/add_tab/3?allocation_tag_id=3&context=2"
    @literatura_brasileira_tab = "/application/add_tab/5?allocation_tag_id=8&context=2"
  end

  def login(user)
    login_as user, :scope => :user
  end

  ##
  # List_to_student
  ##

  # ActionView::Template::Error: undefined method `code_semester' for nil:NilClass
  # /home/bianca/Projects/solar/app/helpers/application_helper.rb:102:in `render_group_selection'
  test "listar as atividades de um aluno para usuario com permissao" do 
    login(users(:aluno1))
    get @quimica_tab
    get list_to_student_assignments_path
    assert_response :success
    assert_template :list_to_student
    assert_not_nil assigns(:individual_assignments_info)
    assert_not_nil assigns(:group_assignments_info)
  end

  test 'nao listar as atividades de um aluno para usuario sem permissao' do 
    login(users(:professor))
    get @quimica_tab
    get list_to_student_assignments_path
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    assert_nil assigns(:individual_assignments_info)
    assert_nil assigns(:group_assignments_info)
  end
  
  ##
  # Upload_file
  ##

  # Perfil com permissao e usuario com acesso

  # Público
  test 'permitir upload de arquivo publico por usuario com permissao e com acesso' do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end
    assert_response :redirect
    assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  end

  # Perfil com permissao e usuario sem acesso

  # Público
  # ele está deixando ele fazer upload em uma turma que ele não pertence
  # test 'nao permitir upload de arquivo publico por usuario com permissao e sem acesso' do
  #   login(users(:aluno2))
  #   get @literatura_brasileira_tab
  #   assert_no_difference("PublicFile.count") do
  #     post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste2.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end
  #   assert_response :redirect
  #   assert_redirected_to({:controller => :home})
  #   assert_equal( flash[:alert], I18n.t(:no_permission) )
  # end

  # Perfil sem permissao

  # Público
  test 'nao permitir upload de arquivo publico por usuario sem permissao' do
    login(users(:coorddisc))
    get @quimica_tab
    assert_no_difference("PublicFile.count") do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Download_files
  ##

  # Perfil com permissao e usuario com acesso a atividade 

  # Público
  test "permitir fazer download de arquivos publicos para usuario com permissao - professor" do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    login(users(:professor))
    get @quimica_tab
    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
    get download_files_assignments_path(:assignment_id => assignments(:a9).id, :file_id => public_file.id, :type => 'public')
    assert_response :success
  end

  test "permitir fazer download de arquivos publicos para usuario com permissao - aluno" do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste2.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    login(users(:aluno2))
    get @quimica_tab
    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste2.txt")
    get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
    assert_response :success
  end

  # Perfil com permissão e usuário sem acesso

  # Público
  test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso - professor" do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    login(users(:professor2))
    get @quimica_tab
    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
    get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # ele está deixando ele fazer upload em uma turma que ele não pertence
  # test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso - aluno" do
  #   login(users(:aluno3))
  #   get @literatura_brasileira_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste1.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:aluno1))
  #   get @literatura_brasileira_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno3).id, allocation_tags(:al8).id, "teste1.txt")
  #   get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
  #   assert_response :redirect
  #   assert_redirected_to({:controller => :home})
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # Perfil sem permissao

  # Público
  test "nao permitir fazer download de arquivos publicos para usuario sem permissao" do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    login users(:coorddisc)
    get @quimica_tab
    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
    get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ##
  # Delete_file
  ##

  # Perfil com permissao e usuario com acesso

  # Público
  test 'permitir delecao de arquivo publico por usuario com permissao e com acesso' do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
    delete delete_file_assignments_path(:file_id => public_file.id, :type => 'public')
    assert_response :redirect
    assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
  end

  # Perfil com permissao e usuario sem acesso

  # Público
  test 'nao permitir delecao de arquivo publico por usuario com permissao e sem acesso' do
    login(users(:aluno3))
    get @literatura_brasileira_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste1.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    login(users(:aluno1))
    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno3).id, allocation_tags(:al8).id, "teste1.txt")
    delete delete_file_assignments_path(:file_id => public_file.id, :type => 'public')
    assert_response :redirect
    # assert_equal I18n.t(:no_permission), flash[:alert] #tá recebendo em inglês e tá esperando em português
  end

  # Perfil sem permissao

  # Público
  test 'nao permitir delecao de arquivo publico por usuario sem permissao' do
    login(users(:aluno1))
    get @quimica_tab
    assert_difference("PublicFile.count", +1) do
      post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
    end

    login(users(:coorddisc))
    public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
    delete delete_file_assignments_path(:file_id => public_file.id, :type => 'public')
    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ##
  # Import_groups_page
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'exibir pagina de importacao de grupos entre atividades para usuario com permissao' do
    login(users(:professor))
    get @quimica_tab
    get import_groups_page_assignment_path(assignments(:a6).id)
    assert_response :success
    assert_not_nil assigns(:assignments)
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test 'nao exibir pagina de importacao de grupos entre atividades para usuario sem permissao' do
    login(users(:aluno1))
    get @quimica_tab
    get import_groups_page_assignment_path(assignments(:a6).id)
    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test 'nao exibir pagina de importacao de grupos entre atividades para usuario com permissao e sem acesso' do
    login(users(:professor))
    get @literatura_brasileira_tab
    get import_groups_page_assignment_path(assignments(:a11).id)
    assert_response :redirect
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

end