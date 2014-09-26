require 'test_helper'

class PublicFilesWithAllocationTagTest < ActionDispatch::IntegrationTest
  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # QM CAU
    @quimica2_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # QM MAR

    @aluno1, @prof, @editor, @user, @tutor, @aluno3 = users(:aluno1), users(:professor), users(:editor), users(:user), users(:tutor_distancia), users(:aluno3)
  end

  test "listar arquivos publicos de um usuario" do
    login @aluno1
    get @quimica_tab

    get public_files_path(user_id: @prof.id)
    assert_template :index
  end

  test "nao listar arquivos publicos de um usuario - sem acesso" do
    login @tutor
    get @quimica2_tab

    get public_files_path(user_id: @prof.id)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  test "nao listar arquivos publicos de um usuario - sem permissao" do
    login @editor
    get @quimica_tab

    get public_files_path(user_id: @prof.id)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  test "enviar arquivo publico" do
    login @aluno1
    get @quimica_tab

    assert_difference("PublicFile.count") do
      # post public_files_path(public_file: {attachment: fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain')}, html: {multipart: true}, referer: '/' )
      # post public_files_path public_file: {attachment: upload_file("public_files", "teste3.txt")}
    end

    assert_response :success
  end

  test "nao enviar arquivo publico - sem acesso" do
    login @tutor
    get @quimica2_tab

  end

  test "nao enviar arquivo publico - sem permissao" do
    login @editor
    get @quimica_tab

  end

  test "fazer download de arquivo publico" do
    login @aluno1
    get @quimica_tab


    login @prof
    get @quimica_tab

  end

  test "nao fazer download de arquivo publico - sem acesso" do
    login @prof
    get @quimica2_tab

    login @tutor
    get @quimica2_tab

  end

  test "deletar arquivo publico" do
    login @aluno1
    get @quimica_tab

  end

  test "nao deletar arquivo publico - sem acesso" do
    login @aluno1
    get @quimica_tab

    login @prof
    get @quimica_tab

  end

end



  # # Perfil com permissao e usuario com acesso

  # # Público
  # test 'permitir upload de arquivo publico por usuario com permissao e com acesso' do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end
  #   assert_response :redirect
  #   assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  # end

  # # Perfil com permissao e usuario sem acesso

  # # Público
  # # test 'nao permitir upload de arquivo publico por usuario com permissao e sem acesso' do
  # #   login(users(:aluno2))
  # #   get @literatura_brasileira_tab
  # #   assert_no_difference("PublicFile.count") do
  # #     post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste2.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  # #   end
  # #   assert_response :redirect
  # #   # assert_equal I18n.t(:no_permission), flash[:alert]
  # # end

  # # Perfil sem permissao

  # # Público
  # test 'nao permitir upload de arquivo publico por usuario sem permissao' do
  #   login(users(:coorddisc))
  #   get @quimica_tab
  #   assert_no_difference("PublicFile.count") do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end
  #   assert_response :redirect
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # ##
  # # Download_files
  # ##

  # # Perfil com permissao e usuario com acesso a atividade 

  # # Público
  # test "permitir fazer download de arquivos publicos para usuario com permissao - professor" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:professor))
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
  #   get download_public_files_assignments_path(file_id: public_file.id)
  #   assert_response :success
  # end

  # test "permitir fazer download de arquivos publicos para usuario com permissao - aluno" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste2.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:aluno2))
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste2.txt")
  #   get download_public_files_assignments_path(:file_id => public_file.id)
  #   assert_response :success
  # end

  # # Perfil com permissão e usuário sem acesso

  # # Público
  # test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso - professor" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:professor2))
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste1.txt")
  #   get download_public_files_assignments_path(file_id: public_file.id)

  #   assert_response :redirect
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso - aluno" do
  # #   login(users(:aluno3))
  # #   get @literatura_brasileira_tab
  # #   assert_difference("PublicFile.count", +1) do
  # #     post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste1.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  # #   end

  # #   login(users(:aluno1))
  # #   get @literatura_brasileira_tab
  # #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno3).id, allocation_tags(:al8).id, "teste1.txt")
  # #   get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
  # #   assert_response :redirect
  # #   assert_redirected_to(home_path)
  # #   assert_equal I18n.t(:no_permission), flash[:alert]
  # # end

  # # Perfil sem permissao

  # # Público
  # test "nao permitir fazer download de arquivos publicos para usuario sem permissao" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login users(:coorddisc)
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
  #   get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
  #   assert_response :redirect
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # ##
  # # Delete_file
  # ##

  # # Perfil com permissao e usuario com acesso

  # # Público
  # test 'permitir delecao de arquivo publico por usuario com permissao e com acesso' do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   assert_difference("PublicFile.count", -1) do
  #     public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
  #     delete delete_file_assignments_path(:file_id => public_file.id, :type => 'public')
  #   end
  #   assert_response :redirect
  #   assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
  # end

  # # Perfil com permissao e usuario sem acesso

  # # Público
  # # test 'nao permitir delecao de arquivo publico por usuario com permissao e sem acesso' do
  # #   login(users(:aluno3))
  # #   get @literatura_brasileira_tab
  # #   assert_difference("PublicFile.count", +1) do
  # #     post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste1.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  # #   end

  # #   login(users(:aluno1))
  # #   assert_no_difference("PublicFile.count") do
  # #     public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno3).id, allocation_tags(:al8).id, "teste1.txt")
  # #     delete delete_file_assignments_path(:file_id => public_file.id, :type => 'public')
  # #   end
  # #   assert_response :redirect
  # #   # assert_equal I18n.t(:no_permission), flash[:alert] #tá recebendo em inglês e tá esperando em português
  # # end

  # # Perfil sem permissao

  # # Público
  # test 'nao permitir delecao de arquivo publico por usuario sem permissao' do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:coorddisc))
  #   assert_no_difference("PublicFile.count") do
  #     public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
  #     delete delete_file_assignments_path(:file_id => public_file.id, :type => 'public')
  #   end
  #   assert_response :redirect
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end


  # ##
  # # Send_comment
  # ##

  # # Novo comentário

  # # Perfil com permissao e usuario com acesso
  # test "permitir comentar em atividade individual para usuario com permissao e com acesso" do
  #   login users(:professor)
  #   get @quimica_tab
  #   assert_difference("CommentFile.count", +1) do
  #     comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
  #     post send_comment_assignment_path(assignments(:a9).id), {:student_id => users(:aluno1).id, :comment => "comentario8", :comment_files => comment_files}
  #   end
  #   assert_response :redirect
  #   assert_equal I18n.t(:comment_sent_success, :scope => [:assignment, :comments]), flash[:notice]
  # end

  # # Perfil com permissao e usuario com acesso, mas fora do período permitido
  # test "nao permitir comentar em atividade individual para usuario com permissao e com acesso e atividade fora do periodo" do
  #   login users(:professor)
  #   get @quimica_tab
  #   assert_no_difference("CommentFile.count") do
  #     comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
  #     post send_comment_assignment_path(assignments(:a15).id), {:student_id => users(:aluno1).id, :comment => "comentario8", :comment_files => comment_files}
  #   end
  # end

  # # Perfil com permissao e usuario sem acesso
  # test "nao permitir comentar em atividade individual para usuario com permissao e sem acesso" do
  #   login users(:professor)
  #   get @literatura_brasileira_tab

  #   assert_no_difference("AssignmentComment.count") do
  #     post send_comment_assignment_path(assignments(:a14).id), {:student_id => users(:aluno1).id, :comment => "comentario9"}
  #   end

  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # Perfil sem permissao e usuario com acesso
  # test "nao permitir comentar em atividade individual para usuario sem permissao e com acesso" do
  #   login users(:aluno1)
  #   get @quimica_tab
  #   assert_no_difference("AssignmentComment.count") do
  #     post send_comment_assignment_path(assignments(:a9).id), {:student_id => users(:aluno1).id, :comment => "comentario10"}
  #   end
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # Editar comentário

  # # Perfil com permissao e usuario com acesso
  # test "permitir editar comentario para usuario com permissao e com acesso" do
  #   login users(:professor)
  #   get @quimica_tab
  #   post send_comment_assignment_path(assignments(:a9).id), {:student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."}
  #   assert_response :redirect
  #   assert_equal I18n.t(:comment_sent_success, :scope => [:assignment, :comments]), flash[:notice]
  # end

  # # Perfil com permissao e usuario com acesso, mas fora do período permitido
  # test "nao permitir editar comentario para usuario com permissao e com acesso e atividade fora do periodo" do
  #   login users(:professor)
  #   get @quimica_tab
  #   post send_comment_assignment_path(assignments(:a14).id), {:student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."}
  #   assert_not_equal assignment_comments(:ac2).comment, "trabalho mediano."    
  # end

  # # Perfil com permissao e usuario sem acesso
  # test "nao permitir editar comentario para usuario com permissao e sem acesso" do
  #   login users(:professor2)
  #   get @quimica_tab
  #   post send_comment_assignment_path(:id => assignments(:a9).id), {:student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho mediano."}
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # Perfil sem permissao e usuario com acesso
  # test "nao permitir editar comentario para usuario sem permissao e com acesso" do
  #   login users(:aluno1)
  #   get @quimica_tab
  #   post send_comment_assignment_path(assignments(:a9).id), {:student_id => users(:aluno1).id, :comment_id => assignment_comments(:ac2).id, :comment => "trabalho otimo."}
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # ##
  # # Remove_comment
  # ##

  # # Perfil com permissao e usuario com acesso
  # test "permitir remover comentario para usuario com permissao e com acesso" do
  #   login users(:professor)
  #   get @quimica_tab
  #   get home_curriculum_unit_path(3)
  #   assert_difference("AssignmentComment.count", -1) do
  #     delete remove_comment_assignment_path(assignments(:a9).id), {:comment_id => assignment_comments(:ac2).id}
  #   end
  #   assert_response :success
  #   get student_assignment_path(assignments(:a9).id), {:student_id => users(:aluno1).id}
  #   assert_no_tag :tag => "table", :attributes => { :class => "assignment_comment tb_comments tb_comment_#{assignment_comments(:ac2).id}" }
  #   assert_template :student
  # end

  # test "permitir professor remover comentario para usuario de atividade fora do periodo" do
  #   login users(:professor)
  #   get @quimica_tab

  #   assert_difference("AssignmentComment.count", -1) do
  #     delete remove_comment_assignment_path(assignments(:a7).id), {comment_id: assignment_comments(:ac5).id}
  #   end
  # end

  # # Perfil com permissao e usuario com acesso, mas fora do período permitido (depois da oferta terminar)
  # test "nao permitir professor remover comentario para usuario de atividade fora do periodo da oferta" do
  #   login users(:professor2)
  #   get @quimica2_tab
  #   get home_curriculum_unit_path(9)

  #   assert_response :success

  #   assert_no_difference("AssignmentComment.count") do
  #     delete remove_comment_assignment_path(assignments(:a16).id), {comment_id: assignment_comments(:ac6).id}
  #   end

  #   assert_response :success
  # end

  # # Perfil com permissao e usuario sem acesso
  # test "nao permitir remover comentario para usuario com permissao e sem acesso" do
  #   login users(:professor2)
  #   get @quimica_tab
  #   get home_curriculum_unit_path(3)

  #   assert_response :redirect

  #   assert_no_difference("AssignmentComment.count") do
  #     delete remove_comment_assignment_path(assignments(:a9).id), {comment_id: assignment_comments(:ac2).id}
  #   end

  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # Perfil sem permissao e usuario com acesso
  # test "nao permitir remover comentario para usuario sem permissao e com acesso" do
  #   login users(:aluno1)
  #   get @quimica_tab
  #   get home_curriculum_unit_path(3)
  #   assert_no_difference("AssignmentComment.count") do
  #     delete remove_comment_assignment_path(assignments(:a9).id), {:comment_id => assignment_comments(:ac2).id}
  #   end
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]

  #   login users(:professor)
  #   get student_assignment_path(assignments(:a9).id), {:student_id => users(:aluno1).id}
  #   assert_template :student
  #   assert_tag :tag => "table", :attributes => { :class => "assignment_comment tb_comment_#{assignment_comments(:ac2).id} tb_comments" }
  # end

  # # Público

  # # Data
  # test "nao permitir upload de arquivo fora do prazo da atividade" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   post upload_file_assignments_path, {assignment_id: assignments(:a7).id, assignment_file: fixture_file_upload('files/assignments/sent_assignment_files/teste5.txt', 'text/plain'), :type => "assignment"}
  #   assert_response :redirect
  #   assert_equal I18n.t(:date_range_expired, :scope => [:assignment, :notifications]), flash[:alert]
  # end

  # test "nao permitir fazer download de arquivos de comentario para usuario com permissao e sem acesso - atividade em grupo" do
  #   login(users(:tutor_distancia))
  #   get @quimica_tab
  #   assert_difference('CommentFile.count', 1) do
  #     comment_files = [fixture_file_upload('files/assignments/comment_files/teste2.txt', content_type: 'text/plain')]
  #     post send_comment_assignment_path(assignments(:a11).id), {comment_files: comment_files, group_id: 1, comment: "comentario"}
  #   end

  #   comment_file = CommentFile.first
    
  #   login(users(:user))
  #   get @quimica_tab
  #   get(download_files_assignments_path, {assignment_id: assignments(:a11).id, file_id: comment_file.id, type: 'comment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # Perfil com permissao e usuario sem acesso

  # # Comentario
  # test "nao permitir fazer download de arquivos de comentario para usuario sem permissao" do
  #   login(users(:professor))
  #   get @quimica_tab
  #   assert_difference('CommentFile.count', +1) do
  #     comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
  #     post send_comment_assignment_path(assignments(:a9).id), {:comment_files => comment_files, :student_id => users(:aluno1).id, :comment => "comentario"}
  #   end
  #   assignment_comment = AssignmentComment.find_by_sent_assignment_id_and_user_id(sent_assignments(:sa3).id, users(:professor).id)
  #   comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comment.id, "teste1.txt")

  #   login(users(:coorddisc))
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  #  # Comentario
  # test "nao permitir fazer download de arquivos de comentario para usuario com permissao e sem acesso" do
  #   login(users(:professor))
  #   get @quimica_tab
  #   assert_difference('CommentFile.count', +1) do
  #     comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
  #     post send_comment_assignment_path(assignments(:a9).id), {:comment_files => comment_files, :student_id => users(:aluno1).id, :comment => "comentario"}
  #   end
  #   assignment_comment = AssignmentComment.find_by_sent_assignment_id_and_user_id(sent_assignments(:sa3).id, users(:professor).id)
  #   comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comment.id, "teste1.txt")

  #   login(users(:professor2))
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]

  #   login(users(:user))
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test "permitir fazer download de arquivos de grupo para usuario com permissao - aluno" do
  #   login(users(:aluno2))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a5).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login(users(:aluno1))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa2).id, "teste2.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :success
  # end

  # # Comentario
  # test "permitir fazer download de arquivos de comentario para usuario com permissao" do
  #   login(users(:professor))
  #   get @quimica_tab
  #   assert_difference('CommentFile.count', +1) do
  #     comment_files = [fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain')]
  #     post send_comment_assignment_path(assignments(:a9).id), {:comment_files => comment_files, :student_id => users(:aluno1).id, :comment => "comentario"}
  #   end
  #   assert_response :redirect

  #   assignment_comment = AssignmentComment.find_by_sent_assignment_id_and_user_id(sent_assignments(:sa3).id, users(:professor).id)
  #   comment_file = CommentFile.find_by_assignment_comment_id_and_attachment_file_name(assignment_comment.id, "teste1.txt")

  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
  #   assert_response :success

  #   login(users(:aluno1))
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => comment_file.id, :type => 'comment'})
  #   assert_response :success
  # end

  # # Aluno
  # test "nao permitir fazer download de arquivos de aluno para usuario sem permissao" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a9).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
  #   end
    
  #   login users(:coorddisc)
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test "nao permitir fazer download de arquivos de aluno para usuario com permissao e sem acesso - professor" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a9).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login(users(:professor2))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test "nao permitir fazer download de arquivos de aluno para usuario com permissao e sem acesso - aluno" do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', 1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a10).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login(users(:aluno1))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa5).id, "teste4.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test 'nao permitir delecao de arquivo enviado pelo aluno por usuario com permissao e sem acesso' do
  #   login (users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a11).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'),:type => "assignment"}
  #   end

  #   login(users(:aluno1))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
  #   delete( delete_file_assignments_path, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :redirect
  #   # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  # end

  # test 'permitir delecao de arquivo enviado pelo aluno por usuario com permissao e com acesso' do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a9).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
  #   end
    
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
  #   assert_difference('AssignmentFile.count', -1) do    
  #     delete(delete_file_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   end

  #   assert_response :redirect
  #   assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
  #   assert_nil flash[:alert]
  #   assert_not_equal I18n.t(:no_permission), flash[:alert]
  # end
    
  # test "permitir fazer download de arquivos de aluno para usuario com permissao" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a9).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :success


  #   login(users(:professor))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa3).id, "teste1.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a9).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :success
  # end

  # test 'permitir upload de arquivo enviado pelo aluno por usuario com permissao e com acesso' do
  #   login users(:aluno1)
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a9).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'), :type => "assignment"}
  #   end
  #   assert_response :redirect
  #   assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  # end

  # test 'nao permitir delecao de arquivo enviado pelo aluno por usuario sem permissao' do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a11).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
  #   end
    
  #   login(users(:coorddisc))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
  #   delete(delete_file_assignments_path, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :redirect
  #   # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  # end

  # test 'permitir delecao de arquivo enviado pelo grupo por usuario com permissao e com acesso' do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a11).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
  #   assert_difference('AssignmentFile.count', -1) do
  #     delete(delete_file_assignments_path, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   end

  #   assert_response :redirect
  #   assert_equal I18n.t(:deleted_success, :scope => [:assignment, :files]), flash[:notice]
  #   assert_nil flash[:alert]
  #   assert_not_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test "permitir fazer download de arquivos de grupo para usuario com permissao - professor" do
  #   login(users(:aluno2))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a5).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login(users(:professor))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa2).id, "teste2.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :success
  # end

  # test 'permitir upload de arquivo enviado pelo grupo por usuario com permissao e com acesso' do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a11).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   assert_response :redirect
  #   assert_equal I18n.t(:uploaded_success, :scope => [:assignment, :files]), flash[:notice]

    
  #   login(users(:aluno2))
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a5).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste2.txt', 'text/plain'), :type => "assignment"}
  #   end
  #   assert_response :redirect
  #   assert_equal(flash[:notice], I18n.t(:uploaded_success, :scope => [:assignment, :files]))
  # end

  # test "nao permitir fazer download de arquivos de grupo para usuario com permissao e sem acesso" do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a11).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login(users(:professor2))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]

  #   login(users(:aluno1))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test "nao permitir fazer download de arquivos de grupo para usuario sem permissao" do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a11).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste3.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login users(:coorddisc)
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa4).id, "teste3.txt")
  #   get(download_files_assignments_path, {:assignment_id => assignments(:a11).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # test 'nao permitir delecao de arquivo enviado pelo grupo por usuario sem permissao' do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a10).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
  #   end

  #   login(users(:coorddisc))
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa5).id, "teste4.txt")
  #   delete(delete_file_assignments_path, {:assignment_id => assignments(:a10).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :redirect
  #   # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  # end

  # test 'nao permitir delecao de arquivo enviado pelo grupo por usuario com permissao e sem acesso' do
  #   login(users(:aluno3))
  #   get @quimica_tab
  #   assert_difference('AssignmentFile.count', +1) do
  #     post upload_file_assignments_path, {:assignment_id => assignments(:a10).id, :assignment_file => fixture_file_upload('files/assignments/sent_assignment_files/teste4.txt', 'text/plain'), :type => "assignment"}
  #   end
    
  #   login users(:aluno2)
  #   assignment_file = AssignmentFile.find_by_sent_assignment_id_and_attachment_file_name(sent_assignments(:sa5).id, "teste4.txt")
  #   delete(delete_file_assignments_path, {:assignment_id => assignments(:a5).id, :file_id => assignment_file.id, :type => 'assignment'})
  #   assert_response :redirect
  #   # assert_equal( flash[:alert], I18n.t(:no_permission) ) #tá recebendo em inglês e tá esperando em português
  # end
   # Perfil com permissao e usuario com acesso a atividade 

  # # Público
  # test "permitir fazer download de arquivos publicos para usuario com permissao - professor" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:professor))
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
  #   get download_public_files_assignments_path(file_id: public_file.id)
  #   assert_response :success
  # end

  # test "permitir fazer download de arquivos publicos para usuario com permissao - aluno" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste2.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:aluno2))
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste2.txt")
  #   get download_public_files_assignments_path(:file_id => public_file.id)
  #   assert_response :success
  # end

  # # Perfil com permissão e usuário sem acesso

  # # Público
  # test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso - professor" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login(users(:professor2))
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste1.txt")
  #   get download_public_files_assignments_path(file_id: public_file.id)

  #   assert_response :redirect
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end

  # # test "nao permitir fazer download de arquivos publicos para usuario com permissao e sem acesso - aluno" do
  # #   login(users(:aluno3))
  # #   get @literatura_brasileira_tab
  # #   assert_difference("PublicFile.count", +1) do
  # #     post upload_file_assignments_path, {:file => fixture_file_upload('/files/assignments/public_files/teste1.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  # #   end

  # #   login(users(:aluno1))
  # #   get @literatura_brasileira_tab
  # #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno3).id, allocation_tags(:al8).id, "teste1.txt")
  # #   get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
  # #   assert_response :redirect
  # #   assert_redirected_to(home_path)
  # #   assert_equal I18n.t(:no_permission), flash[:alert]
  # # end

  # # Perfil sem permissao

  # # Público
  # test "nao permitir fazer download de arquivos publicos para usuario sem permissao" do
  #   login(users(:aluno1))
  #   get @quimica_tab
  #   assert_difference("PublicFile.count", +1) do
  #     post upload_file_assignments_path, {:public_file => fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain'), :type => "public"}, { :html => {:multipart => true}, :referer => '/' }
  #   end

  #   login users(:coorddisc)
  #   get @quimica_tab
  #   public_file = PublicFile.find_by_user_id_and_allocation_tag_id_and_attachment_file_name(users(:aluno1).id, allocation_tags(:al3).id, "teste3.txt")
  #   get download_files_assignments_path(:file_id => public_file.id, :type => 'public')
  #   assert_response :redirect
  #   assert_redirected_to(home_path)
  #   assert_equal I18n.t(:no_permission), flash[:alert]
  # end