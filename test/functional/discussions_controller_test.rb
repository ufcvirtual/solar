require 'test_helper'

class DiscussionsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
  end

  ## API - Mobilis
  test "lista de foruns da turma FOR de introducao a liguistica" do
    sign_in users(:aluno1)
    assert_routing '/groups/1/discussions', {:controller => "discussions", :action => "index", :group_id => "1"}

    get :index, {:format => 'json', :group_id => 1}
    assert_response :success
    assert_not_nil assigns(:discussions)
  end


  ##
  # Edicao
  ##

  test "listar foruns" do
    quimica = allocation_tags(:al3).id

    get :list, {allocation_tags_ids: [quimica]}
    assert_response :success
  end

  test "nao listar foruns para usuario sem permissao" do
    quimica = allocation_tags(:al3).id
    sign_in users(:aluno1)

    get :list, {allocation_tags_ids: [quimica]}

    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "criar forum" do
    #turmas
    assert_difference(["Discussion.count", "Schedule.count"], 1) do
      assert_difference(["AcademicAllocation.count"], 3) do
        post :create, {allocation_tags_ids: "#{allocation_tags(:al3).id} #{allocation_tags(:al11).id} #{allocation_tags(:al22).id}", discussion: {name: "Testa modulo3", description: "Assignment para testar modulo", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
      end
    end

    assert_equal I18n.t(:created, scope: [:discussion, :success]), get_json_response("notice")
    assert_response :success

    # oferta
    assert_difference(["Discussion.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, {allocation_tags_ids: "#{allocation_tags(:al6).id}", discussion: {name: "Testa modulo3", description: "Forum para testar modulo", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_equal I18n.t(:created, scope: [:discussion, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao criar forum - sem permissao" do
    sign_in users(:aluno1)

    assert_no_difference(["Discussion.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, {allocation_tags_ids: "#{allocation_tags(:al6).id}", discussion: {name: "Testa modulo3", description: "Forum para testar modulo", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "nao criar forum para curso ou uc - permite apenas turma ou oferta" do
    params_uc     = {allocation_tags_ids: "#{allocation_tags(:al13).id}", discussion: {name: "Testa modulo2", description: "Forum para testar modulo", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    params_course = {allocation_tags_ids: "#{allocation_tags(:al19).id}", discussion: {name: "Testa modulo3", description: "Forum para testar modulo", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}

    assert_no_difference(["Discussion.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, params_uc
      post :create, params_course
    end

    assert_equal I18n.t(:not_associated), get_json_response("alert")
    assert_response :unprocessable_entity
  end

   test "editar forum" do
    assert_no_difference(["Discussion.count", "AcademicAllocation.count"]) do
      put(:update, {id: discussions(:forum_8).id, discussion: {name: "Forum alterado"}, allocation_tags_ids: [allocation_tags(:al3).id]})
    end

    assert_equal "Forum alterado", Discussion.find(discussions(:forum_8).id).name
    assert_equal I18n.t(:updated, scope: [:discussion, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao editar forum - sem permissao" do
    sign_in users(:aluno1)

    assert_no_difference(["Discussion.count", "AcademicAllocation.count"]) do
      put(:update, {id: discussions(:forum_8).id, discussion: {name: "Forum alterado"}, allocation_tags_ids: [allocation_tags(:al3).id]})
    end

    assert_not_equal "Forum alterado", Discussion.find(discussions(:forum_8).id).name
    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "deletar um forum" do
    assert_difference(["Discussion.count", "AcademicAllocation.count"], -1) do
      delete(:destroy, {id: discussions(:forum_8).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    end

    assert_equal I18n.t(:deleted, scope: [:discussion, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao deletar um forum - sem permissao" do
    sign_in users(:aluno1)
    
    assert_no_difference(["Discussion.count", "AcademicAllocation.count"]) do
      delete(:destroy, {id: discussions(:forum_8).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    end

    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "deletar varios foruns" do
    discussions = [6,7,8]
    assert_difference(["Discussion.count", "AcademicAllocation.count"], -discussions.count) do
      delete(:destroy, {id: discussions, allocation_tags_ids: [allocation_tags(:al3).id]})
    end

    assert_equal I18n.t(:deleted, scope: [:discussion, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao deletar um forum se tiver posts" do
    assert_no_difference(["Discussion.count", "AcademicAllocation.count"]) do
      delete(:destroy, {id: discussions(:forum_1).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    end

    assert_equal I18n.t(:discussion_with_posts, scope: [:discussion, :errors]), get_json_response("alert")
    assert_response :unprocessable_entity
  end  

end
