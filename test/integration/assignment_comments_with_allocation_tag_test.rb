require 'test_helper'

class CommentWithAllocationTagTest < ActionDispatch::IntegrationTest
  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # QM CAU
    @quimica2_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # QM MAR

    @aluno1, @prof, @editor, @user, @tutor, @aluno3 = users(:aluno1), users(:professor), users(:editor), users(:user), users(:tutor_distancia), users(:aluno3)
    @atividadeG, @sa1, @sa2, @c01 = assignments(:a4), academic_allocation_users(:sa2), academic_allocation_users(:sa11), assignment_comments(:ac1)
  end

  test "envia comentario" do
    login @prof
    get @quimica_tab

    assert_difference("Comment.count") do
      post comments_path assignment_comment: {academic_allocation_user_id: @sa1.id, user_id: @prof.id, comment: "Comentário"}
    end

    assert_response :success
    assert_template :comment
  end

  test "nao envia comentario - sem conteudo" do
    login @prof
    get @quimica_tab

    assert_no_difference("Comment.count") do
      post comments_path assignment_comment: {academic_allocation_user_id: @sa1.id, user_id: @prof.id, comment: ""}
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t('assignment_comments.error.general_message'), get_json_response("alert")
  end

  test "envia comentario - sem academic_allocation_user existente" do
    login @prof
    get @quimica_tab

    assert_difference("SentAssignment.count") do
      get new_comment_path assignment_id: @atividadeG.id, group_id: group_assignments(:a2).id
    end

    assert_difference("Comment.count") do
      post comments_path assignment_comment: {academic_allocation_user_id: assigns(:academic_allocation_user).id, user_id: @prof.id, comment: "Comentário"}
    end

    assert_response :success
    assert_template :comment
  end

  test "nao envia comentario - sem permissao" do
    login @aluno1
    get @quimica_tab

    assert_no_difference("Comment.count") do
      post comments_path assignment_comment: {academic_allocation_user_id: @sa1.id, user_id: @prof.id, comment: "Comentário"}
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao envia comentario - sem acesso" do
    login @tutor
    get @quimica2_tab

    assert_no_difference("Comment.count") do
      post comments_path assignment_comment: {academic_allocation_user_id: @sa2.id, user_id: @tutor.id, comment: "Comentário"}
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  # test "nao envia comentario - periodo encerrado" do
  #   # login @prof
  #   # get @quimica_tab

  #   # procurar assignment com oferta já encerrada
  # end

  test "edita comentario" do
    login @user
    get @quimica_tab

    put comment_path id: @c01.id, assignment_comment: {comment: "Alterando comentário"}
    assert_response :success
  end

  test "nao edita comentario - sem acesso" do
    login @tutor
    get @quimica_tab

    put comment_path id: @c01.id, assignment_comment: {comment: "Alterando comentário"}
    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "remove comentario" do
    login @user
    get @quimica_tab

    assert_difference("Comment.count", -1) do
      delete comment_path id: @c01.id
    end
    assert_response :success
  end

  test "nao remove comentario - sem acesso" do
    login @tutor
    get @quimica_tab

    assert_no_difference("Comment.count") do
      delete comment_path id: @c01.id
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  # test "download de arquivos do comentario" do
  #   # enviar comentário com arquivo e depois remover
  # end

end