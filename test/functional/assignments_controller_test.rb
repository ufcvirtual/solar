require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :send_assignments

  ##
  # List
  ##

  test "listar as atividiades de uma turma para usuario com permissao" do 
    sign_in users(:professor)
    get :list
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_template :list
  end

  test "nao listar as atividiades de uma turma para usuario sem permissao" do 
    sign_in users(:aluno1)
    get :list
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # List_to_student
  # => assignments_with_allocation_tag_test.rb
  ##
  
  ##
  # Information
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir informacoes da atividade individual para usuario com permissao" do
    sign_in users(:professor)
    get(:information, {:id => assignments(:a9).id})   
    assert_response :success
    assert_not_nil assigns(:assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_not_nil assigns(:students)
    assert_nil assigns(:groups)
    assert_nil assigns(:students_without_group)
    assert_template :information
  end

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir informacoes da atividade em grupo para usuario com permissao" do
    sign_in users(:professor)
    get(:information, {:id => assignments(:a6).id})   
    assert_response :success
    assert_not_nil assigns(:assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_nil assigns(:students)
    assert_not_nil assigns(:groups)
    assert_not_nil assigns(:students_without_group)
    assert_template :information
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test "nao exibir informacoes da atividade individual para usuario sem permissao" do
    sign_in users(:aluno1)
    get(:information, {:id => assignments(:a9).id})   
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test "nao exibir informacoes da atividade em grupo para usuario sem permissao" do
    sign_in users(:aluno1)
    get(:information, {:id => assignments(:a6).id})   
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir informacoes da atividade individual para usuario com permissao e sem acesso" do
    sign_in users(:professor)
    get(:information, {:id => assignments(:a10).id})    
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir informacoes da atividade em grupo para usuario com permissao e sem acesso" do
    sign_in users(:professor)
    get(:information, {:id => assignments(:a11).id})    
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ##
  # Manage_groups
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'permitir a gerenciamento de grupos para usuario com permissao' do
    sign_in users(:professor)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga6).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a6).id, :groups => groups_hash})
    assert_response :success
    assert_template :group_assignment_content_div
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
  test 'nao permitir o gerenciamento de grupos para usuario com permissao e sem acesso' do
    sign_in users(:professor)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga7).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a11).id, :groups => groups_hash})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out users(:professor)

    # não está dando sign out
    sign_in users(:tutor_distancia)
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
  test 'nao permitir o gerenciamento de grupos para usuario sem permissao e com acesso' do
    sign_in users(:aluno3)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga7).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a11).id, :groups => groups_hash})
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out users(:professor)

    # não está dando sign out
    sign_in users(:tutor_distancia)
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
    sign_in users(:professor)
    get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})
    assert_response :success
    assert_not_nil assigns(:student_id)
    assert_nil assigns(:group_id)
    assert_nil assigns(:group)
    assert_not_nil assigns(:send_assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_not_nil assigns(:send_assignment_files)
    assert_not_nil assigns(:comments)
    assert_template :show
  end

  # Perfil com permissao e usuario com acesso a atividade
  test "exibir pagina de avaliacao da atividade em grupo para usuario com permissao" do
    sign_in users(:professor)
    get(:show, {:id => assignments(:a6).id, :student_id => users(:aluno1).id, :group_id => group_assignments(:ga6).id})
    assert_response :success
    assert_nil assigns(:student_id)
    assert_not_nil assigns(:group_id)
    assert_not_nil assigns(:group)
    assert_nil assigns(:send_assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_nil assigns(:send_assignment_files)
    assert_nil assigns(:comments)
    assert_template :show
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir pagina de avaliacao da atividade individual para usuario com permissao e sem acesso" do
    sign_in users(:aluno2)
    get(:show, {:id => assignments(:a9).id}, :student_id => users(:aluno1).id)    
    assert_response :redirect
    # assert_equal I18n.t(:no_permission), flash[:alert]
    # Expected response to be a redirect to <http://test.host/home> but was a redirect to <http://test.host/>
    # assert_redirected_to({:controller => :home})
    #<"Você precisa logar antes de continuar."> expected but was
    # <"Você não tem permissão para acessar esta página">.
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test "nao exibir pagina de avaliacao da atividade em grupo para usuario com permissao e sem acesso" do
    sign_in users(:aluno3)
    get(:show, {:id => assignments(:a6).id, :student_id => users(:aluno2).id, :group_id => group_assignments(:ga6).id})   
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ##
  # Evaluate
  #

  # Perfil com permissao e usuario com acesso
  test "permitir avaliar atividade individual para usuario com permissao" do
    sign_in users(:professor)
    post(:evaluate, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :grade => 7})
    assert_response :success
    assert_template :evaluate_assignment_div
  end

  # Perfil com permissao e usuario com acesso, mas fora do período permitido
  test "nao permitir avaliar atividade individual para usuario com permissao e atividade fora do periodo" do
    sign_in users(:professor)
    post(:evaluate, {:id => assignments(:a14).id, :student_id => users(:aluno1).id, :grade => 7})
    assert (SendAssignment.find_by_assignment_id_and_user_id(assignments(:a9).id, users(:aluno1).id).grade != 7) # não realizou mudança
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir avaliar atividade individual para usuario com permissao e sem acesso" do
    sign_in users(:professor)
    post(:evaluate, {:id => assignments(:a10).id, :student_id => users(:aluno1).id, :grade => 7})
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir avaliar atividade individual para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    post(:evaluate, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :grade => 10})
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
    sign_in users(:professor)
    assert_difference("CommentFile.count", +1) do
      comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
      post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "comentario8", :comment_files => comment_files})
    end
    assert_response :redirect
    assert_equal I18n.t(:comment_sent_success, :scope => [:assignment, :comments]), flash[:notice]
  end

  # Perfil com permissao e usuario com acesso, mas fora do período permitido
  test "nao permitir comentar em atividade individual para usuario com permissao e com acesso e atividade fora do periodo" do
    sign_in users(:professor)
    assert_no_difference("CommentFile.count") do
      comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
      post(:send_comment, {:id => assignments(:a14).id, :student_id => users(:aluno1).id, :comment => "comentario8", :comment_files => comment_files})
    end
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir comentar em atividade individual para usuario com permissao e sem acesso" do
    sign_in users(:professor)
    assert_no_difference("AssignmentComment.count") do
      post(:send_comment, {:id => assignments(:a10).id, :student_id => users(:aluno1).id, :comment => "comentario9"})
    end
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir comentar em atividade individual para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    assert_no_difference("AssignmentComment.count") do
      post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "comentario10"})
    end
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Editar comentário
  
  # Perfil com permissao e usuario com acesso
  test "permitir editar comentario para usuario com permissao e com acesso" do
    sign_in users(:professor)
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."})
    assert_response :redirect
    assert_equal I18n.t(:comment_sent_success, :scope => [:assignment, :comments]), flash[:notice]
  end

  # Perfil com permissao e usuario com acesso, mas fora do período permitido
  test "nao permitir editar comentario para usuario com permissao e com acesso e atividade fora do periodo" do
    sign_in users(:professor)
    post(:send_comment, {:id => assignments(:a14).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."})
    assert_not_equal assignment_comments(:ac2).comment, "trabalho mediano."    
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir editar comentario para usuario com permissao e sem acesso" do
    sign_in users(:professor2)
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."})
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir editar comentario para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho otimo."})
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  ##
  # Remove_comment
  ##

  # Perfil com permissao e usuario com acesso
  test "permitir remover comentario para usuario com permissao e com acesso" do
    sign_in users(:professor)
    assert_difference("AssignmentComment.count", -1) do
      delete(:remove_comment, {:id => assignments(:a9).id, :comment_id => assignment_comments(:ac2).id})
    end
    assert_response :success
    get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})    
    assert_no_tag :tag => "table", :attributes => { :class => "assignment_comment tb_comments tb_comment_#{assignment_comments(:ac2).id}" }
    assert_template :show
  end

  # Perfil com permissao e usuario com acesso, mas fora do período permitido
  test "nao permitir remover comentario para usuario com permissao e com acesso e atividade fora do periodo" do
    sign_in users(:professor)
    assert_no_difference("AssignmentComment.count") do
      delete(:remove_comment, {:id => assignments(:a14).id, :comment_id => assignment_comments(:ac2).id})
    end
  end

  # Perfil com permissao e usuario sem acesso
  test "nao permitir remover comentario para usuario com permissao e sem acesso" do
    sign_in users(:professor2)
    assert_no_difference("AssignmentComment.count") do
      delete(:remove_comment, {:id => assignments(:a9).id, :comment_id => assignment_comments(:ac2).id})
    end
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
    sign_out users(:professor2)

    # sign_in users(:professor)
    # get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})    
    # assert_response :success
    # assert_tag :tag => "table", :attributes => { :class => "assignment_comment tb_comments tb_comment_#{assignment_comments(:ac2).id}" }
  end

  # Perfil sem permissao e usuario com acesso
  test "nao permitir remover comentario para usuario sem permissao e com acesso" do
    sign_in users(:aluno1)
    assert_no_difference("AssignmentComment.count") do
      delete(:remove_comment, {:id => assignments(:a9).id, :comment_id => assignment_comments(:ac2).id})
    end
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
    sign_out users(:aluno1)

    sign_in users(:professor)
    get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})    
    assert_template :show
    assert_tag :tag => "table", :attributes => { :class => "assignment_comment tb_comment_#{assignment_comments(:ac2).id} tb_comments" }
  end

  ##
  # Import_groups_page
  # => assignments_with_allocation_tag_test.rb
  ##

  ##
  # Import_groups
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'permitir a importacao de grupos entre atividades para usuario com permissao' do
    sign_in users(:professor)
    post(:import_groups, {:id => assignments(:a6).id, :assignment_id_import_from => assignments(:a5).id})   
    assert_redirected_to(information_assignment_path(assignments(:a6)))
    assert_equal(flash[:notice], I18n.t(:import_success, :scope => [:assignment, :import_groups]))
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test 'nao permitir a importacao de grupos entre atividades para usuario com permissao e sem acesso' do
    sign_in users(:professor)
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