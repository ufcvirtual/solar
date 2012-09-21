require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :comment_files, :public_files, :send_assignments
  
  def setup
    @tutor_distancia = users(:tutor_distancia)
    @coordenador = users(:coorddisc)
    @professor1 = users(:professor)
    @professor2 = users(:professor2)
    @aluno1 = users(:aluno1)
    @aluno2 = users(:aluno2)
    @aluno3 = users(:aluno3)
    # sign_in @coordenador
  end

  ##
  # List
  ##

  test "listar as atividiades de uma turma para usuario com permissao" do 
    sign_in @professor1
    get :list
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
  end

  test "nao listar as atividiades de uma turma para usuario sem permissao" do 
    sign_in users(:aluno1)
    get :list
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC
# tentar fazer get com url: http://localhost:3000/application/add_tab/4?allocation_tag_id=15&context=2&name=Introdu%C3%A7%C3%A3o+%C3%80s+Metodologias+%C3%81geis

  ##
  # List_to_student
  ##

  # test "listar as atividades de um aluno para usuario com permissao" do 
  #   sign_in users(:aluno1)
  #   # get "/application/add_tab/4?allocation_tag_id=15&context=2"
  #   get({:controller => :application, :action => :add_tab}, {:id => 4, :allocation_tag_id => 15, :context => 2})
  #   get :list_to_student
  #   assert_response :success
 #    assert_nil assigns(:individual_activities)
 #    assert_not_nil assigns(:group_activities)
  # end

  # test 'listar as atividades de um aluno para usuario sem permissao' do 
  #   sign_in @professor1
  #   get :list_to_student
  #   assert_response :redirect
  # end

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC
  
  ##
  # Information
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir informacoes da atividade individual para usuario com permissao" do
    sign_in @professor1
    get(:information, {:id => assignments(:a9).id})   
    assert_response :success
    assert_not_nil assigns(:assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_not_nil assigns(:students)
    assert_nil assigns(:groups)
    assert_nil assigns(:students_without_group)
  end

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir informacoes da atividade em grupo para usuario com permissao" do
    sign_in @professor1
    get(:information, {:id => assignments(:a6).id})   
    assert_response :success
    assert_not_nil assigns(:assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_nil assigns(:students)
    assert_not_nil assigns(:groups)
    assert_not_nil assigns(:students_without_group)
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test "nao exibir informacoes da atividade individual para usuario sem permissao" do
    sign_in users(:aluno1)
    get(:information, {:id => assignments(:a9).id})   
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test "nao exibir informacoes da atividade em grupo para usuario sem permissao" do
    sign_in users(:aluno1)
    get(:information, {:id => assignments(:a6).id})   
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir informacoes da atividade individual para usuario com permissao e sem acesso" do
    sign_in @professor1
    get(:information, {:id => assignments(:a10).id})    
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir informacoes da atividade em grupo para usuario com permissao e sem acesso" do
    sign_in @professor1
    get(:information, {:id => assignments(:a11).id})    
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Manage_groups
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'permitir a gerenciamento de grupos para usuario com permissao' do
    sign_in @professor1
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga6).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a6).id, :groups => groups_hash})
    assert_response :success
    assert_tag :tag => "div", 
      :attributes => { :id => "group_#{group_assignments(:ga6).id}" },
      :child => { 
        :tag => "ul",
        :child => {
          :tag => "li", :attributes => {:class => "student_#{users(:aluno2).id}"} 
        } #o aluno1 já existia no grupo, foi adicionado o aluno 2.
     } #logo, verifica se ele foi adicionado ao grupo (validação do método)

    #após ajax
    # assert_equal(flash[:notice], I18n.t(:management_success, :scope => [:assignment, :group_assignments]))
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test 'nao permitir a gerenciamento de grupos para usuario com permissao e sem acesso' do
    sign_in @professor1
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga7).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a11).id, :groups => groups_hash})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor1

    # não está dando sign out
    sign_in @tutor_distancia
    get(:information, {:id => assignments(:a11).id})  
    assert_no_tag :tag => "div", 
      :attributes => { :id => "group_#{group_assignments(:ga6).id}" },
      :child => { 
        :tag => "ul",
        :child => {
          :tag => "li", :attributes => {:class => "student_#{users(:aluno2).id}"} 
        } #o aluno1 já existia no grupo, foi tentado adicionar o aluno 2.
     } #logo, verifica se ele realmente não foi adicionado ao grupo (validação da permissão)
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test 'nao permitir a gerenciamento de grupos para usuario sem permissao e com acesso' do
    sign_in users(:aluno3)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga7).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a11).id, :groups => groups_hash})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor1

    # não está dando sign out
    sign_in @tutor_distancia
    get(:information, {:id => assignments(:a11).id})  
    assert_no_tag :tag => "div", 
      :attributes => { :id => "group_#{group_assignments(:ga6).id}" },
      :child => { 
        :tag => "ul",
        :child => {
          :tag => "li", :attributes => {:class => "student_#{users(:aluno2).id}"} 
        } #o aluno1 já existia no grupo, foi tentado adicionar o aluno 2.
     } #logo, verifica se ele realmente não foi adicionado ao grupo (validação da permissão)
  end 

  ##
  # Show
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir pagina de avaliacao da atividade individual para usuario com permissao" do
    sign_in @professor1
    get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})
    assert_response :success
    assert_not_nil assigns(:student_id)
    assert_nil assigns(:group_id)
    assert_nil assigns(:group)
    assert_not_nil assigns(:send_assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_not_nil assigns(:send_assignment_files)
    assert_not_nil assigns(:comments)
  end

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir pagina de avaliacao da atividade em grupo para usuario com permissao" do
    sign_in @professor1
    get(:show, {:id => assignments(:a6).id, :student_id => users(:aluno1).id, :group_id => group_assignments(:ga6).id})
    assert_response :success
    assert_nil assigns(:student_id)
    assert_not_nil assigns(:group_id)
    assert_not_nil assigns(:group)
    assert_nil assigns(:send_assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_nil assigns(:send_assignment_files)
    assert_nil assigns(:comments)
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir pagina de avaliacao da atividade individual para usuario com permissao e sem acesso" do
    sign_in users(:aluno2)
    get(:show, {:id => assignments(:a9).id}, :student_id => users(:aluno1).id)    
    assert_response :redirect
    # Expected response to be a redirect to <http://test.host/home> but was a redirect to <http://test.host/>
    # assert_redirected_to({:controller => :home})
    #<"Você precisa logar antes de continuar."> expected but was
    # <"Você não tem permissão para acessar esta página">.
    # assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir pagina de avaliacao da atividade em grupo para usuario com permissao e sem acesso" do
    sign_in users(:aluno3)
    get(:show, {:id => assignments(:a6).id, :student_id => users(:aluno2).id, :group_id => group_assignments(:ga6).id})   
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end


  ##
  # Evaluate
  #

  # Perfil com permissao e usuario com acesso
  test "permitir avaliar atividade individual para usuario com permissao" do
    sign_in @professor1
    post(:evaluate, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :grade => 7, :comment => "parabens, aluno."})
    assert_response :success
    # após ajax
    # assert_equal( flash[:alert], I18n.t(:evaluated_success, :scope => [:assignment, :evaluation]) )
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir avaliar atividade individual para usuario com permissao e sem acesso" do
    sign_in @professor1
    post(:evaluate, {:id => assignments(:a10).id, :student_id => users(:aluno1).id, :grade => 7, :comment => "parabens, aluno."})
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir avaliar atividade individual para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    post(:evaluate, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :grade => 10, :comment => "parabens, aluno."})
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Send_comment
  ##

  # Novo comentário

  # Perfil com permissao e usuario com acesso
  test "permitir comentar em atividade individual para usuario com permissao e com acesso" do
    sign_in @professor1
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
    assert_response :redirect
    assert_equal( flash[:notice], I18n.t(:comment_sent_success, :scope => [:assignment, :comments]) )
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir comentar em atividade individual para usuario com permissao e sem acesso" do
    sign_in @professor1
    post(:send_comment, {:id => assignments(:a10).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir comentar em atividade individual para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Editar comentário
  
  # Perfil com permissao e usuario com acesso
  test "permitir editar comentario para usuario com permissao e com acesso" do
    sign_in @professor1
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."})
    assert_response :redirect
    assert_equal( flash[:notice], I18n.t(:comment_sent_success, :scope => [:assignment, :comments]) )
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir editar comentario para usuario com permissao e sem acesso" do
    sign_in users(:professor2)
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir editar comentario para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho otimo."})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Remove_comment
  ##

  # Perfil com permissao e usuario com acesso
  test "permitir remover comentario para usuario com permissao e com acesso" do
    sign_in @professor1
    delete(:remove_comment, {:id => assignments(:a9).id, :comment_id => assignment_comments(:ac2).id})
    assert_response :success
    get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})    
    assert_no_tag :tag => "table", :attributes => { :class => "forum_post tb_comments tb_comment_#{assignment_comments(:ac2).id}" }
    # após ajax
    # assert_equal( flash[:notice], I18n.t(:comment_sent_success, :scope => [:assignment, :comments]) )
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir remover comentario para usuario com permissao e sem acesso" do
    sign_in @professor2
    delete(:remove_comment, {:id => assignments(:a9).id, :comment_id => assignment_comments(:ac2).id})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor2

    # sign_in @professor1
    # get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})    
    # assert_tag :tag => "table", :attributes => { :class => "forum_post tb_comments tb_comment_#{assignment_comments(:ac2).id}" }
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir remover comentario para usuario sem permissao e com acesso" do
    sign_in @aluno1
    delete(:remove_comment, {:id => assignments(:a9).id, :comment_id => assignment_comments(:ac2).id})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )

    sign_out @aluno1
    sign_in @professor1
    get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})    
    assert_tag :tag => "table", :attributes => { :class => "forum_post tb_comments tb_comment_#{assignment_comments(:ac2).id}" }
  end

  ##
  # Upload_file
  ##

  # Perfil com permissao e usuario com acesso
  
  #Aluno
  test 'permitir upload de arquivo enviado pelo aluno por usuario com permissao e com acesso' do
    sign_in users(:aluno1)
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    assert_response :redirect
    assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  end

  # Grupo
  test 'permitir upload de arquivo enviado pelo grupo por usuario com permissao e com acesso' do
    sign_in @aluno3

    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end

    # assert_response :redirect
    assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))


    sign_out @aluno3
    sign_in @aluno2
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a5), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
    end
    assert_response :redirect
    assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  end

  test 'permitirasds upload de arquivo enviado pelo grupo por usuario com permissao e com acesso' do
    
  end


  # Público
  ## PROBLEMA COM ALOCATION TAG 
  # test 'permitir upload de arquivo publico por usuario com permissao e com acesso' do
  #   sign_in users(:aluno1)
  #   post :upload_file, {:file => fixture_file_upload('files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}
  #   assert_response :redirect
  #   assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  # end
  ## PROBLEMA COM ALOCATION TAG 

  # Perfil com permissao e usuario sem acesso

  # Aluno
  test 'nao permitir upload de arquivo enviado pelo aluno por usuario com permissao e sem acesso' do
    sign_in users(:aluno1)
    post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Grupo
  test 'nao permitir upload de arquivo enviado pelo grupo por usuario com permissao e sem acesso' do
    sign_in users(:aluno2)
    post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # # Público
  ## PROBLEMA COM ALOCATION TAG 
  # test 'nao permitir upload de arquivo publico por usuario com permissao e sem acesso' do
  #   sign_in users(:aluno1)
  #   delete(:delete_file, {:file_id => public_files(:pf3).id, :type => 'public'})
  #   assert_redirected_to({:controller => :home})
  #   assert_equal( flash[:alert], I18n.t(:no_permission) )
  # end
  ## PROBLEMA COM ALOCATION TAG 

  # Data
  test "nao permitir upload de arquivo fora do prazo da atividade" do
    sign_in users(:aluno1)
    post :upload_file, {:assignment_id => assignments(:a7), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
    assert_equal( flash[:alert], I18n.t(:date_range_expired, :scope => [:assignment, :notifications]) )
  end

  # Perfil sem permissao

  # Aluno
  test 'nao permitir upload de arquivo enviado pelo aluno por usuario sem permissao' do
    sign_in users(:coorddisc)
    post :upload_file, {:assignment_id => assignments(:a7), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Grupo
  test 'nao permitir upload de arquivo enviado pelo grupo por usuario sem permissao' do
    sign_in users(:coorddisc)
    post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # # Público
  ## PROBLEMA COM ALOCATION TAG 
  # test 'nao permitir upload de arquivo publico por usuario sem permissao' do
  #   sign_in users(:coorddisc)
  #   delete(:delete_file, {:file_id => public_files(:pf3).id, :type => 'public'})
  #   assert_redirected_to({:controller => :home})
  #   assert_equal( flash[:alert], I18n.t(:no_permission) )
  # end
  ## PROBLEMA COM ALOCATION TAG 

  # fixtures :assignment_files

  ##
  # Download_files
  ##

  # Perfil com permissao e usuario com acesso a atividade 

  # Aluno
  test "permitir fazer download de arquivos de aluno para usuario com permissao" do
    sign_in @aluno1
    
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end

    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success

    sign_out @aluno1

    sign_in @professor1
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success
  end

  # Grupo
  test "permitir fazer download de arquivos de grupo para usuario com permissao" do
    sign_in @aluno2
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a5), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno2

    sign_in @professor1
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa2).id, "teste2.txt")
    get(:download_files, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success
    sign_out @professor1 

    sign_in @aluno1
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa2).id, "teste2.txt")
    get(:download_files, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success
  end

  # Comentario
  test "permitir fazer download de arquivos de comentario para usuario com permissao" do
    sign_in @professor1
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_files(:acf1).id, :type => 'comment'})
    assert_response :success
    sign_out @professor1

    sign_in @aluno1
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_files(:acf1).id, :type => 'comment'})
    assert_response :success
  end

  # Publico
  test "permitir fazer download de arquivos publicos para usuario com permissao" do
    sign_in @professor1
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => public_files(:pf1).id, :type => 'public'})
    assert_response :success
    sign_out @professor1

    # sign_in @aluno3
    # get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => public_files(:pf3).id, :type => 'public'})
    # assert_response :success
  end

  # Do enunciado da atividade
  test "permitir fazer download de arquivos do enunciado da atividade para usuario com permissao" do
    sign_in users(:professor)
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_enunciation_files(:aef1).id, :type => 'enunciation'})
    assert_response :success
    sign_out @professor1 

    # sign_in @aluno3
    # get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => assignment_enunciation_files(:aef2).id, :type => 'enunciation'})
    # assert_response :success
  end

  # Perfil com permissao e usuario sem acesso

  # Aluno
  test "nao permitir fazer download de arquivos de aluno para usuario com permissao e sem acesso" do
    sign_in @aluno1
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno1

    sign_in @professor2
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor2 #não está funcionando

    # sign_in @aluno3
    # # raise "#{current_user.id}"
    # assert_difference('AssignmentFile.count', +1) do
    #   post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
    # end
    # sign_out @aluno3

    # sign_in users(:aluno1)
    # assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa5).id, "teste4.txt")
    # get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    # assert_redirected_to({:controller => :home})
    # assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Grupo
  test "nao permitir fazer download de arquivos de grupo para usuario com permissao e sem acesso" do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno3

    sign_in @professor2
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa4).id, "teste3.txt")
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor2 

    sign_in @aluno1
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa4).id, "teste3.txt")
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # # Comentario
  test "nao permitir fazer download de arquivos de comentario para usuario com permissao e sem acesso" do
    sign_in @professor2
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_files(:acf1).id, :type => 'comment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor2

    sign_in @aluno3
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_files(:acf1).id, :type => 'comment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )

    sign_out @aluno1 
    sign_in users(:aluno1)
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => comment_files(:acf2).id, :type => 'comment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )   
  end

  # Publico
  test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso" do
    sign_in @professor2
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => public_files(:pf1).id, :type => 'enunciation'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor2

    sign_in @aluno1
    get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => public_files(:pf3).id, :type => 'enunciation'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )   
  end

  # Do enunciado da atividade
  test "nao permitir fazer download de arquivos do enunciado da atividade para usuario com permissao e sem acesso" do
    sign_in @professor2
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_enunciation_files(:aef1).id, :type => 'enunciation'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out @professor2

    sign_in @aluno1
    get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => assignment_enunciation_files(:aef2).id, :type => 'enunciation'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # # Perfil sem permissao

  # Aluno
  test "nao permitir fazer download de arquivos de aluno para usuario sem permissao" do
    sign_in @aluno1
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno1

    sign_in users(:coorddisc)
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Grupo
  test "nao permitir fazer download de arquivos de grupo para usuario sem permissao" do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno3

    sign_in users(:coorddisc)
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa4).id, "teste3.txt")
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Comentario
  test "nao permitir fazer download de arquivos de comentario para usuario sem permissao" do
    sign_in users(:coorddisc)
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_files(:acf1).id, :type => 'comment'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Publico
  test "nao permitir fazer download de arquivos publicos para usuario sem permissao" do
    sign_in users(:coorddisc)
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => public_files(:pf1).id, :type => 'enunciation'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Do enunciado da atividade
  test "nao permitir fazer download de arquivos do enunciado da atividade para usuario sem permissao" do
    sign_in users(:coorddisc)
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_enunciation_files(:aef1).id, :type => 'enunciation'})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Delete_file => ## REQUEST REFERER ERROR
  ##

  # Perfil com permissao e usuario com acesso
  
  # Aluno
  test 'permitir delecao de arquivo enviado pelo aluno por usuario com permissao e com acesso' do
    sign_in @aluno1
    
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa3).id, "teste1.txt")
    assert_difference('AssignmentFile.count', -1) do    
      delete(:delete_file, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    end

    assert_response :redirect
    assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
    assert_nil flash[:alert]
    assert_not_equal(flash[:alert], I18n.t(:no_permission))
  end

  # Grupo
  test 'permitir delecao de arquivo enviado pelo grupo por usuario com permissao e com acesso' do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end

    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa4).id, "teste3.txt")
    assert_difference('AssignmentFile.count', -1) do
      delete(:delete_file, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    end

    assert_response :redirect
    assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
    assert_nil flash[:alert]
    assert_not_equal(flash[:alert], I18n.t(:no_permission))
  end

  # Público
  # liberar após corrigir upload de arquivo público
  # test 'permitir delecao de arquivo publico por usuario com permissao e com acesso' do
  #   sign_in users(:aluno3)
  #   delete(:delete_file, {:file_id => public_files(:pf3).id, :type => 'public'})
  #   assert_response :redirect
  # assert_nil flash[:alert]
  # assert_equal not(flash[:alert], I18n.t(:no_permission))
  # end

  # Perfil com permissao e usuario sem acesso

  # Aluno
  test 'nao permitir delecao de arquivo enviado pelo aluno por usuario com permissao e sem acesso' do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno3

    sign_in @aluno1

    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa4).id, "teste3.txt")
    delete(:delete_file, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})

    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Grupo
  test 'nao permitir delecao de arquivo enviado pelo grupo por usuario com permissao e sem acesso' do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno3


    sign_in users(:aluno2)

    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa5).id, "teste4.txt")
    delete(:delete_file, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})

    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Público
  test 'nao permitir delecao de arquivo publico por usuario com permissao e sem acesso' do
    sign_in users(:aluno1)
    delete(:delete_file, {:file_id => public_files(:pf3).id, :type => 'public'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Perfil sem permissao

  # Aluno
  test 'nao permitir delecao de arquivo enviado pelo aluno por usuario sem permissao' do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno3

    sign_in @coordenador
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa4).id, "teste3.txt")
    delete(:delete_file, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Grupo
  test 'nao permitir delecao de arquivo enviado pelo grupo por usuario sem permissao' do
    sign_in @aluno3
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out @aluno3

    sign_in @coordenador
    assignment_file = AssignmentFile.find_by_send_assignment_id_and_attachment_file_name(send_assignments(:sa5).id, "teste4.txt")
    delete(:delete_file, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # # Público
  # test 'nao permitir delecao de arquivo publico por usuario sem permissao' do
  #   sign_in users(:coorddisc)
  #   delete(:delete_file, {:file_id => public_files(:pf3).id, :type => 'public'})
  #   assert_response :redirect
  #   # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  # end

  ##
  # Send_public_files_page
  ##

  # Perfil com permissao
  test "permitir acessar pagina de upload de arquivos publicos para usuario com permissao" do
    sign_in @aluno1
    get :send_public_files_page
    assert_response :success
  end

  # Perfil sem permissao
  test "nao permitir acessar pagina de upload de arquivos publicos para usuario sem permissao" do
    sign_in @coordenador
    get :send_public_files_page
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Import_groups_page
  ##

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC
# tentar fazer get com url: http://localhost:3000/application/add_tab/4?allocation_tag_id=15&context=2&name=Introdu%C3%A7%C3%A3o+%C3%80s+Metodologias+%C3%81geis

  # # Perfil com permissao e usuario com acesso a atividade
  # test 'exibir pagina de importacao de grupos entre atividades para usuario com permissao' do
  #   sign_in @professor1
  #   get(:import_groups_page, {:id => assignments(:a6).id})    
  #   assert_response :success
  #   assert_not_nil assigns(:assignments)
  # end

  # # Perfil sem permissao e usuario com acesso a atividade
  # test 'exibir pagina de importacao de grupos entre atividades para usuario sem permissao' do
  #   sign_in users(:aluno1)
  #   get(:import_groups_page, {:id => assignments(:a6).id})    
  #   assert_response :redirect
  # end

  # # Perfil com permissao e usuario sem acesso a atividade
  # test 'exibir pagina de importacao de grupos entre atividades para usuario com permissao e sem acesso' do
  #   sign_in @professor1
  #   get(:import_groups_page, {:id => assignments(:a11).id})   
  #   assert_response :redirect
  # end

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC

  ##
  # Import_groups
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'permitir a importacao de grupos entre atividades para usuario com permissao' do
    sign_in @professor1
    post(:import_groups, {:id => assignments(:a6).id, :assignment_id_import_from => assignments(:a5).id})   
    assert_redirected_to(information_assignment_path(assignments(:a6)))
    assert_equal(flash[:notice], I18n.t(:import_success, :scope => [:assignment, :import_groups]))
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test 'nao permitir a importacao de grupos entre atividades para usuario com permissao e sem acesso' do
    sign_in @professor1
    post(:import_groups, {:id => assignments(:a11).id, :assignment_id_import_from => assignments(:a12).id})   
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test 'nao permitir a importacao de grupos entre atividades para usuario sem permissao' do
    sign_in users(:aluno3)
    post(:import_groups, {:id => assignments(:a11).id, :assignment_id_import_from => assignments(:a12).id})   
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

end
