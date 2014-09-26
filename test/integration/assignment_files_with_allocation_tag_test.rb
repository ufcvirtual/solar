require 'test_helper'

class AssignmentFilesWithAllocationTagTest < ActionDispatch::IntegrationTest
  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)  # QM CAU
    @quimica2_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 11) # QM MAR

    @aluno1, @prof, @editor, @user, @tutor, @aluno3 = users(:aluno1), users(:professor), users(:editor), users(:user), users(:tutor_distancia), users(:aluno3)
  end

  test "enviar arquivo para um trabalho individual" do
    login @aluno1
    get @quimica_tab

    assert_difference(["AssignmentFile.count", "SentAssignment.count"]) do
      # envio de arquivo
    end

    assert_response :success
  end

  test "enviar arquivo para um trabalho em grupo" do
    login @aluno1
    get @quimica_tab

    assert_difference(["AssignmentFile.count", "SentAssignment.count"]) do
      # envio de arquivo
    end

    assert_response :success
  end

  test "nao enviar arquivo - sem acesso" do
    login @aluno3
    get @quimica_tab

    assert_no_difference(["AssignmentFile.count", "SentAssignment.count"]) do
      # envio de arquivo pro @aluno1
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao enviar arquivo - sem acesso ao grupo" do
    login @aluno3
    get @quimica_tab

    assert_no_difference(["AssignmentFile.count", "SentAssignment.count"]) do
      # envio de arquivo pro mesmo grupo que o aluno1 mandou
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao enviar arquivo - sem permissao" do
    login @tutor
    get @quimica_tab

    assert_no_difference(["AssignmentFile.count", "SentAssignment.count"]) do
      # envio de arquivo
    end

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "fazer download do arquivo individual" do
    login @aluno1
    get @quimica_tab

    # envio de arquivo
    # download

    login @prof
    get @quimica_tab

    # download

  end

  test "fazer download do arquivo de grupo" do
    login @aluno1
    get @quimica_tab

    # envio de arquivo


    login @aluno2 # grupo com aluno1 e aluno2
    get @quimica_tab

    # download

    login @prof
    get @quimica_tab

    # download

  end

  test "nao fazer download de arquivo individual - sem acesso" do
    login @aluno1
    get @quimica_tab

    # envio de arquivo

    login @aluno3
    get @quimica_tab

    # download

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "nao fazer download de arquivo de grupo - sem acesso" do
    login @aluno1
    get @quimica_tab

    # envio de arquivo pro grupo

    login @aluno3
    get @quimica_tab

    # download

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

  test "deletar arquivo" do
    login @aluno1
    get @quimica_tab

    # envia arquivo
    # remove

  end

  test "nao deletar arquivo publico - sem acesso" do
    login @aluno1
    get @quimica_tab

    # envia arquivo pra grupo

    login @prof
    get @quimica_tab

    # remove

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")

    login @aluno2 # só o dono pode remover o arquivo, mesmo que em grupo
    get @quimica_tab

    # remove

    assert_response :unauthorized
    assert_equal I18n.t(:no_permission), get_json_response("alert")
  end

end
