require 'test_helper'
 
# Aqui estão os testes dos métodos do controller scores_teacher
# que, para acessá-los, se faz necessário estar em uma unidade
# curricular. Logo, há a necessidade de acessar o método
# "add_tab" de outro controller. O que não é permitido em testes
# funcionais.

class ScoresTeacherWithAllocationTagTest < ActionDispatch::IntegrationTest
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
  # List
  ##

  # Usuário com permissão e acesso
  # ActionView::Template::Error: No route matches {:action=>"show", :controller=>"scores", :student_id=>7}
  # test "exibir acompanhamento de uma turma para usuario com permissao e acesso" do 
  #   login(users(:professor))
  #   get @quimica_tab
  #   # get scores_teacher_list_path
  #   # get "/scores_teacher/list"
  #   assert_response :success
  #   assert_not_nil assigns(:group)
  #   assert_not_nil assigns(:assignments)
  #   assert_not_nil assigns(:students)
  #   assert_not_nil assigns(:cores)
  #   assert_template :list
  # end

  # Usuário com permissão e sem acesso

  # Usuário sem permissão

end