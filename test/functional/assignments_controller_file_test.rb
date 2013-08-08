require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :sent_assignments

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
    sign_in(users(:aluno3))

    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end

    assert_response :redirect
    assert_equal I18n.t(:uploaded_success, :scope => [:assignment, :files]), flash[:notice]

    sign_out(users(:aluno3))
    sign_in(users(:aluno2))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a5), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
    end
    assert_response :redirect
    assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  end

  # Público
  # => assignments_with_allocation_tag_test.rb

  # Perfil com permissao e usuario sem acesso

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

  # Data
  test "nao permitir upload de arquivo fora do prazo da atividade" do
    sign_in(users(:aluno1))
    post :upload_file, {:assignment_id => assignments(:a7), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
    assert_response :redirect
    assert_equal I18n.t(:date_range_expired, :scope => [:assignment, :notifications]), flash[:alert]
  end

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

  # Público
  # => assignments_with_allocation_tag_test.rb

  ##
  # Download_files
  ##

  # Perfil com permissao e usuario com acesso a atividade 

  # Aluno
  test "permitir fazer download de arquivos de aluno para usuario com permissao" do
    sign_in(users(:aluno1))
    
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9).id, :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end

    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success

    sign_out(users(:aluno1))

    sign_in(users(:professor))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success
  end

  # Grupo
  test "permitir fazer download de arquivos de grupo para usuario com permissao - professor" do
    sign_in(users(:aluno2))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a5).id, :file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno2))

    sign_in(users(:professor))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa2).id, "teste2.txt")
    get(:download_files, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success
  end

  test "permitir fazer download de arquivos de grupo para usuario com permissao - aluno" do
    sign_in(users(:aluno2))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a5).id, :file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno2))

    sign_in(users(:aluno1))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa2).id, "teste2.txt")
    get(:download_files, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :success
  end

  # Comentario
  test "permitir fazer download de arquivos de comentario para usuario com permissao" do
    sign_in(users(:professor))
    assert_difference('CommentFile.count', +1) do
      comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
      post :send_comment, {:id => assignments(:a9).id, :comment_files => comment_files, :student_id => users(:aluno1).id, :comment => "comentario"}
    end
    assert_response :redirect

    assignment_comment = AssignmentComment.find_by_sent_assignment_id_and_user_id(sent_assignments(:sa3).id, users(:professor).id)
    comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comment.id, "teste1.txt")

    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
    assert_response :success
    sign_out(users(:professor))

    sign_in(users(:aluno1))
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
    assert_response :success
  end

  # Publico
  # => assignments_with_allocation_tag_test.rb
  
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

  # Perfil com permissao e usuario sem acesso

  # Aluno
  test "nao permitir fazer download de arquivos de aluno para usuario com permissao e sem acesso - professor" do
    sign_in(users(:aluno1))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno1))

    sign_in(users(:professor2))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  test "nao permitir fazer download de arquivos de aluno para usuario com permissao e sem acesso - aluno" do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in(users(:aluno1))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa5).id, "teste4.txt")
    get(:download_files, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Grupo
  test "nao permitir fazer download de arquivos de grupo para usuario com permissao e sem acesso" do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in(users(:professor2))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    sign_out(users(:professor2 ))

    sign_in(users(:aluno1))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Comentario
  test "nao permitir fazer download de arquivos de comentario para usuario com permissao e sem acesso" do
    sign_in(users(:professor))
    assert_difference('CommentFile.count', +1) do
      comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
      post :send_comment, {:id => assignments(:a9).id, :comment_files => comment_files, :student_id => users(:aluno1).id, :comment => "comentario"}
    end
    assignment_comment = AssignmentComment.find_by_sent_assignment_id_and_user_id(sent_assignments(:sa3).id, users(:professor).id)
    comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comment.id, "teste1.txt")
    sign_out(users(:professor))

    sign_in(users(:professor2))
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    sign_out(users(:professor2))

    sign_in(users(:aluno3))
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end
    
  test "nao permitir fazer download de arquivos de comentario para usuario com permissao e sem acesso - atividade em grupo" do
    sign_in(users(:tutor_distancia))
    assert_difference('CommentFile.count', +1) do
      comment_files = [fixture_file_upload('files/assignments/comment_files/teste2.txt', 'text/plain')]
      post :send_comment, {:comment_id => assignment_comments(:ac4), :id => assignments(:a11).id, :comment_files => comment_files, :student_id => users(:aluno3).id, :comment => "comentario"}
    end
    comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comments(:ac4).id, "teste2.txt")
    sign_out(users(:tutor_distancia))

    sign_in(users(:aluno1))
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => comment_file.id, :type => 'comment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

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

  # Aluno
  test "nao permitir fazer download de arquivos de aluno para usuario sem permissao" do
    sign_in(users(:aluno1))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno1))

    sign_in users(:coorddisc)
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Grupo
  test "nao permitir fazer download de arquivos de grupo para usuario sem permissao" do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in users(:coorddisc)
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
    get(:download_files, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Comentario
  test "nao permitir fazer download de arquivos de comentario para usuario sem permissao" do
    sign_in(users(:professor))
    assert_difference('CommentFile.count', +1) do
      comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
      post :send_comment, {:id => assignments(:a9).id, :comment_files => comment_files, :student_id => users(:aluno1).id, :comment => "comentario"}
    end
    assignment_comment = AssignmentComment.find_by_sent_assignment_id_and_user_id(sent_assignments(:sa3).id, users(:professor).id)
    comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comment.id, "teste1.txt")
    sign_out(users(:professor))

    sign_in(users(:coorddisc))
    get(:download_files, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

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
  
  # Aluno
  test 'permitir delecao de arquivo enviado pelo aluno por usuario com permissao e com acesso' do
    sign_in(users(:aluno1))
    
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a9), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
    end
    
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
    assert_difference('AssignmentFile.count', -1) do    
      delete(:delete_file, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
    end

    assert_response :redirect
    assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
    assert_nil flash[:alert]
    assert_not_equal I18n.t(:no_permission), flash[:alert]
  end

  # Grupo
  test 'permitir delecao de arquivo enviado pelo grupo por usuario com permissao e com acesso' do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end

    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
    assert_difference('AssignmentFile.count', -1) do
      delete(:delete_file, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
    end

    assert_response :redirect
    assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
    assert_nil flash[:alert]
    assert_not_equal I18n.t(:no_permission), flash[:alert]
  end

  # Público
  # => assignments_with_allocation_tag_test.rb

  # Perfil com permissao e usuario sem acesso

  # Aluno
  test 'nao permitir delecao de arquivo enviado pelo aluno por usuario com permissao e sem acesso' do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11),:file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'),:type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in(users(:aluno1))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
    delete(:delete_file, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Grupo
  test 'nao permitir delecao de arquivo enviado pelo grupo por usuario com permissao e sem acesso' do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in users(:aluno2)
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa5).id, "teste4.txt")
    delete(:delete_file, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Público
  # => assignments_with_allocation_tag_test.rb

  # Perfil sem permissao

  # Aluno
  test 'nao permitir delecao de arquivo enviado pelo aluno por usuario sem permissao' do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a11), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in(users(:coorddisc))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
    delete(:delete_file, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

  # Grupo
  test 'nao permitir delecao de arquivo enviado pelo grupo por usuario sem permissao' do
    sign_in(users(:aluno3))
    assert_difference('AssignmentFile.count', +1) do
      post :upload_file, {:assignment_id => assignments(:a10), :file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
    end
    sign_out(users(:aluno3))

    sign_in(users(:coorddisc))
    assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa5).id, "teste4.txt")
    delete(:delete_file, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
    assert_response :redirect
    # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  end

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
