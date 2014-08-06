require 'test_helper'
 
# Aqui estão os testes dos métodos do controller scores
# que, para acessá-los, se faz necessário estar em uma unidade
# curricular. Logo, há a necessidade de acessar o método
# "add_tab" de outro controller. O que não é permitido em testes
# funcionais.

class ScoresWithAllocationTagTest < ActionDispatch::IntegrationTest
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  def setup
    @quimica_tab               = add_tab_path(id: 3, context:2, allocation_tag_id: 3)
    @literatura_brasileira_tab = add_tab_path(id: 5, context:2, allocation_tag_id: 8)
    @from_date  = Date.current
    @until_date = Date.current
  end

  ##
  # Show
  ##

  # Usuário com permissão e acesso

  test "listar as atividades de um aluno para usuario com permissao e acesso - aluno" do 
    login(users(:aluno1))
    get @quimica_tab
    get home_curriculum_unit_path(3)
    get info_scores_path

    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_not_nil assigns(:discussions)
    assert_not_nil assigns(:student)
    assert_not_nil assigns(:amount)
    assert_template :info
  end

  test "listar as atividades de um aluno para usuario com permissao e acesso - professor" do 
    login(users(:professor))
    get @quimica_tab
    get home_curriculum_unit_path(3)
    get student_info_scores_path(users(:aluno1).id)
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_not_nil assigns(:discussions)
    assert_not_nil assigns(:student)
    assert_not_nil assigns(:amount)
    assert_template :info
  end

  # Usuário com permissão e sem acesso
  test "nao listar as atividades de um aluno para usuario com permissao e sem acesso - aluno" do 
    login(users(:aluno1))

    get @quimica_tab
    get home_curriculum_unit_path(3)
    get student_info_scores_path(users(:aluno2).id)

    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
  end

  # Usuário sem permissão
  test "nao listar as atividades de um aluno para usuario sem permissao" do 
    login(users(:coorddisc))

    get @quimica_tab
    get home_curriculum_unit_path(3)
    get student_info_scores_path(users(:aluno1).id)

    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:individual_activities)
    assert_nil assigns(:group_activities)
    assert_nil assigns(:discussions)
    assert_nil assigns(:student)
    assert_nil assigns(:amount)
  end

  ##
  # Amount_history_access
  ## Não existe resource para o método ##
  ##

  # Usuário com permissão e acesso

  test "exibir quantidade de acessos do aluno a unidade curricular para usuario com permissao e acesso - aluno" do 
    login(users(:aluno1))
    get @quimica_tab
    get amount_history_access_scores_path(id: users(:aluno1).id, from_date: @from_date, until_date: @until_date.to_param)

    assert_response :success
    assert_not_nil assigns(:student_id)
    assert_not_nil assigns(:amount)
  end

  test "exibir quantidade de acessos do aluno a unidade curricular para usuario com permissao e acesso - professor" do 
    login(users(:professor))
    get @quimica_tab
    get "/scores/amount_history_access", id: users(:aluno1).id, from_date: @from_date, until_date: @until_date.to_param
    assert_response :success
    assert_not_nil assigns(:student_id)
    assert_not_nil assigns(:amount)
  end

  # Usuário com permissão e sem acesso
  test "nao exibir quantidade de acessos do aluno a unidade curricular para usuario com permissao e sem acesso - aluno" do 
    login(users(:aluno1))
    get @quimica_tab
    get "/scores/amount_history_access", id: users(:aluno3).id, from_date: @from_date, until_date: @until_date.to_param
    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_not_nil assigns(:student_id)
    assert_nil assigns(:amount)
  end

  # Usuário sem permissão

  test "nao exibir quantidade de acessos do aluno a unidade curricular para usuario sem permissao" do 
    login(users(:coorddisc))
    get @quimica_tab
    get "/scores/amount_history_access?#{users(:aluno3).id.to_param}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:from_date)
    assert_nil assigns(:until_date)
    assert_nil assigns(:student_id)
    assert_nil assigns(:amount)
  end  

  ##
  # History_access
  ## Não existe resource para o método ##
  ##

  # Usuário com permissão e acesso

  test "exibir historico de acesso do aluno para usuario com permissao e acesso" do 
    login(users(:aluno1))
    get @quimica_tab
    get history_access_score_path(id: users(:aluno1).id, from_date: @from_date, until_date: @until_date.to_param)

    assert_response :success
    assert_not_nil assigns(:history)

    login(users(:professor))
    get @quimica_tab
    get history_access_score_path(id: users(:aluno1).id, from_date: @from_date, until_date: @until_date.to_param)

    assert_response :success
    assert_not_nil assigns(:history)
  end

  # Usuário com permissão e sem acesso
  test "nao exibir historico de acesso do aluno para usuario com permissao e sem acesso - aluno" do 
    login(users(:aluno1))
    get @quimica_tab
    get history_access_score_path(id: users(:aluno3).id, from_date: @from_date, until_date: @until_date.to_param)

    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:history)
  end

  # Usuário sem permissão

  test "nao exibir historico de acesso do aluno para usuario sem permissao" do 
    login(users(:coorddisc))
    get @quimica_tab
    get history_access_score_path(id: users(:aluno3).id, from_date: @from_date, until_date: @until_date.to_param)

    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:history)
  end  

  ##
  # Index
  ##

  # Usuário com permissão e acesso
  test "exibir acompanhamento de uma turma para usuario com permissao e acesso" do 
    login(users(:professor))
    get @quimica_tab
    get scores_path
    assert_response :success
    assert_not_nil assigns(:group)
    assert_not_nil assigns(:assignments)
    assert_not_nil assigns(:students)
    assert_not_nil assigns(:scores)
    assert_template :index
  end

  # Usuário sem permissão
  test "nao exibir acompanhamento de uma turma para usuario sem permissao" do 
    login(users(:aluno1))
    get @quimica_tab
    get scores_path
    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:group)
    assert_nil assigns(:assignments)
    assert_nil assigns(:students)
    assert_nil assigns(:scores)
  end

end
