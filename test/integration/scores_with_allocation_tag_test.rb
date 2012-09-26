require 'test_helper'
 
# Aqui estão os testes dos métodos do controller scores
# que, para acessá-los, se faz necessário estar em uma unidade
# curricular. Logo, há a necessidade de acessar o método
# "add_tab" de outro controller. O que não é permitido em testes
# funcionais.

class ScoresWithAllocationTagTest < ActionDispatch::IntegrationTest
  fixtures :all
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  # para reconhecer o método "fixture_file_upload" no teste de integração
  include ActionDispatch::TestProcess

  def setup
    @quimica_tab = "/application/add_tab/3?allocation_tag_id=3&context=2"
    @literatura_brasileira_tab = "/application/add_tab/5?allocation_tag_id=8&context=2"
    @from_date = Date.current
    @until_date = Date.current
  end

  def login(user)
    login_as user, :scope => :user
  end

  ##
  # Show
  ##

  # Usuário com permissão e acesso

  test "listar as atividades de um aluno para usuario com permissao e acesso" do 
    login(users(:aluno1))
    get @quimica_tab
    get score_path(allocation_tags(:al3).id)
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_not_nil assigns(:discussions)
    assert_not_nil assigns(:student)
    assert_not_nil assigns(:amount)
    assert_template :show

    login(users(:professor))
    get @quimica_tab
    get score_path(allocation_tags(:al3).id)
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_not_nil assigns(:discussions)
    assert_not_nil assigns(:student)
    assert_not_nil assigns(:amount)
    assert_template :show    
  end

  # Usuário com permissão e sem acesso

  test "nao listar as atividades de um aluno para usuario com permissao e sem acesso" do 
    login(users(:aluno1))
    get @quimica_tab
    get score_path(allocation_tags(:al3).id, :student_id => users(:aluno2).id)
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:individual_activities)
    assert_nil assigns(:group_activities)
    assert_nil assigns(:discussions)
    assert_not_nil assigns(:student)
    assert_nil assigns(:amount)

    # professor de outra turma pode acessar o acompanhamento de uma
    # login(users(:professor))
    # get @literatura_brasileira_tab
    # get score_path(allocation_tags(:al8).id, :student_id => users(:aluno3).id)
    # assert_response :redirect
    # assert_redirected_to({:controller => :home})
    # assert_equal I18n.t(:no_permission), flash[:alert]
    # assert_nil assigns(:individual_activities)
    # assert_nil assigns(:group_activities)
    # assert_nil assigns(:discussions)
    # assert_not_nil assigns(:student)
    # assert_nil assigns(:amount)
  end  

  # Usuário sem permissão

  test "nao listar as atividades de um aluno para usuario sem permissao" do 
    login(users(:coorddisc))
    get @quimica_tab
    get score_path(allocation_tags(:al3).id, :student_id => users(:aluno1).id)
    assert_response :redirect
    assert_redirected_to({:controller => :home})
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

  test "exibir quantidade de acessos do aluno a unidade curricular para usuario com permissao e acesso" do 
    login(users(:aluno1))
    get @quimica_tab
    get "/scores/amount_history_access/#{users(:aluno1).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :success
    assert_not_nil assigns(:from_date)
    assert_not_nil assigns(:until_date)
    assert_not_nil assigns(:student_id)
    assert_not_nil assigns(:amount)

    login(users(:professor))
    get @quimica_tab
    get "/scores/amount_history_access/#{users(:aluno1).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :success
    assert_not_nil assigns(:from_date)
    assert_not_nil assigns(:until_date)
    assert_not_nil assigns(:student_id)
    assert_not_nil assigns(:amount)
  end

  # Usuário com permissão e sem acesso
  # professor de outra turma pode acessar o acompanhamento de uma
  test "nao exibir quantidade de acessos do aluno a unidade curricular para usuario com permissao e sem acesso" do 
    login(users(:aluno1))
    get @quimica_tab
    get "/scores/amount_history_access/#{users(:aluno3).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_not_nil assigns(:student_id)
    assert_nil assigns(:amount)

    # login(users(:professor))
    # get @quimica_tab
    # get "/scores/amount_history_access/#{users(:aluno3).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    # assert_response :redirect
    # assert_redirected_to({:controller => :home})
    # assert_equal I18n.t(:no_permission), flash[:alert]
    # assert_nil assigns(:from_date)
    # assert_nil assigns(:until_date)
    # assert_nil assigns(:student_id)
    # assert_nil assigns(:amount)
  end  

  # Usuário sem permissão

  test "nao exibir quantidade de acessos do aluno a unidade curricular para usuario sem permissao" do 
    login(users(:coorddisc))
    get @quimica_tab
    get "/scores/amount_history_access/#{users(:aluno3).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :redirect
    assert_redirected_to({:controller => :home})
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
    get "/scores/history_access/#{users(:aluno1).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :success
    assert_not_nil assigns(:history)

    login(users(:professor))
    get @quimica_tab
    get "/scores/history_access/#{users(:aluno1).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :success
    assert_not_nil assigns(:history)
  end

  # Usuário com permissão e sem acesso
  # professor de outra turma pode acessar o acompanhamento de uma
  test "nao exibir historico de acesso do aluno para usuario com permissao e sem acesso" do 
    login(users(:aluno1))
    get @quimica_tab
    get "/scores/history_access/#{users(:aluno3).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:history)

    # login(users(:professor))
    # get @literatura_brasileira_tab
    # get "/scores/history_access/#{users(:aluno3).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    # assert_response :redirect
    # assert_redirected_to({:controller => :home})
    # assert_equal I18n.t(:no_permission), flash[:alert]
    # assert_nil assigns(:history)
  end  

  # Usuário sem permissão

  test "nao exibir historico de acesso do aluno para usuario sem permissao" do 
    login(users(:coorddisc))
    get @quimica_tab
    get "/scores/history_access/#{users(:aluno3).id}?#{@from_date.to_param}&#{@until_date.to_param}"
    assert_response :redirect
    assert_redirected_to({:controller => :home})
    assert_equal I18n.t(:no_permission), flash[:alert]
    assert_nil assigns(:history)
  end  

end