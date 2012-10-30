require 'test_helper'

class DiscussionsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:aluno1)
  end

  ## API - Mobilis
  test "lista de foruns da turma FOR de introducao a liguistica" do
    assert_routing '/groups/1/discussions', {:controller => "discussions", :action => "index", :group_id => "1"}

    get :index, {:format => 'json', :group_id => 1}
    assert_response :success
    assert_not_nil assigns(:discussions)
  end

  ##
  # Listar fóruns de uma oferta, de todas as turmas da oferta ou de uma turma (list)
  ##

    test "listar foruns de acordo com dados de oferta e turma passados" do
      sign_in users(:coorddisc)
      get :list, {:offer_id => offers(:of3).id, :group_id => "all"}
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:discussions)
      assert_not_nil assigns(:responsible_or_student)
      assert_not_nil assigns(:group_code)
      assert_not_nil assigns(:offer_semester)
      
      assert_template :list
    end

    test "nao listar foruns de acordo com dados de oferta e turma passados - sem permissao" do
      sign_in users(:professor)
      get :list, {:offer_id => offers(:of3).id, :group_id => "all"}
      assert_nil assigns(:offer_id)
      assert_nil assigns(:group_id)
      assert_nil assigns(:discussions)
      assert_nil assigns(:responsible_or_student)
      assert_nil assigns(:group_code)
      assert_nil assigns(:offer_semester)
      
      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)
    end

end
