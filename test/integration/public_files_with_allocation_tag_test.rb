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

  # test "enviar arquivo publico" do
  #   login @aluno1
  #   get @quimica_tab

  #   assert_difference("PublicFile.count") do
  #     # post public_files_path(public_file: {attachment: fixture_file_upload('/files/assignments/public_files/teste3.txt', 'text/plain')}, html: {multipart: true}, referer: '/' )
  #     # post public_files_path public_file: {attachment: upload_file("public_files", "teste3.txt")}
  #   end

  #   assert_response :success
  # end

  # test "nao enviar arquivo publico - sem acesso" do
  #   login @tutor
  #   get @quimica2_tab

  # end

  # test "nao enviar arquivo publico - sem permissao" do
  #   login @editor
  #   get @quimica_tab

  # end

  # test "fazer download de arquivo publico" do
  #   login @aluno1
  #   get @quimica_tab


  #   login @prof
  #   get @quimica_tab

  # end

  # test "nao fazer download de arquivo publico - sem acesso" do
  #   login @prof
  #   get @quimica2_tab

  #   login @tutor
  #   get @quimica2_tab

  # end

  # test "deletar arquivo publico" do
  #   login @aluno1
  #   get @quimica_tab

  # end

  # test "nao deletar arquivo publico - sem acesso" do
  #   login @aluno1
  #   get @quimica_tab

  #   login @prof
  #   get @quimica_tab

  # end

end
