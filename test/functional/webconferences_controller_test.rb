require 'test_helper'

class WebconferencesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)

    @valid_params = { title: "Lorem ipsum dolor sit amet.", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", initial_time: Time.now + 1.day, duration: 20 }
    @invalid_params = { description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", duration: 20 }

    @quimica = allocation_tags(:al3).id
  end

  test "rotas" do
    assert_routing({method: :get, path: "/webconferences/list"}, {controller: "webconferences", action: "list"})

    assert_routing({method: :put, path: "/webconferences/1/unbind/group/1"}, {controller: "groups", action: "change_tool", tool_id: "1", id: "1", type: "unbind", tool_type: "Webconference"})
    assert_routing({method: :put, path: "/webconferences/1/remove/group/1"}, {controller: "groups", action: "change_tool", tool_id: "1", id: "1", type: "remove", tool_type: "Webconference"})
    assert_routing({method: :put, path: "/webconferences/1/add/group/1"}   , {controller: "groups", action: "change_tool", tool_id: "1", id: "1", type: "add"   , tool_type: "Webconference"})
  end

  test "edition - list" do
    get :list, {allocation_tags_ids: [@quimica]}

    assert_response :success
    assert_not_nil assigns(:webconferences)
  end

  test "edition - create" do
    assert_difference(["AcademicAllocation.count", "Webconference.count"], 1) do
      post :create, {allocation_tags_ids: "#{@quimica}", webconference: @valid_params}
    end
  end

  test "edition - do not create without permission" do
    sign_in users(:aluno1)

    webconference = webconferences(:webc1)
    assert_no_difference(["AcademicAllocation.count", "Webconference.count"]) do
      post :create, {allocation_tags_ids: "#{@quimica}", webconference: @valid_params}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "edition - do not create if data is invalid" do
    assert_no_difference(["AcademicAllocation.count", "Webconference.count"]) do
      post :create, {allocation_tags_ids: "#{@quimica}", webconference: @invalid_params}
    end

    assert_template :new
  end

  test "edition - update" do
    new_title = "new title"
    webconference = webconferences(:webc1)
    assert_equal "Lorem ipsum dolor sit amet.", webconference.title

    assert_no_difference(["AcademicAllocation.count", "Webconference.count"]) do
      put :update, {id: webconference.id, allocation_tags_ids: "#{@quimica}", webconference: {title: new_title}}
    end

    assert_equal new_title, Webconference.find(webconference.id).title
  end

  test "edition - do not update without permission" do
    sign_in users(:aluno1)

    webconference = webconferences(:webc1)
    assert_no_difference(["AcademicAllocation.count", "Webconference.count"]) do
      put :update, {id: webconference.id, allocation_tags_ids: "#{@quimica}", webconference: {title: "new title"}}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "edition - do not update if data is invalid" do
    webconference = webconferences(:webc1)
    assert_no_difference(["AcademicAllocation.count", "Webconference.count"]) do
      put :update, {id: webconference.id, allocation_tags_ids: "#{@quimica}", webconference: {title: nil}}
    end

    assert_template :edit
  end

  test "edition - delete" do
    webconference = webconferences(:webc1)

    assert_difference(["AcademicAllocation.count", "Webconference.count"], -1) do
      delete :destroy, {id: webconference.id, allocation_tags_ids: [@quimica]}
    end
  end

  test "edition - do not delete without permission" do
    sign_in users(:aluno1)
    webconference = webconferences(:webc2)

    assert_no_difference(["AcademicAllocation.count", "Webconference.count"]) do
      delete :destroy, {id: webconference.id, allocation_tags_ids: [@quimica]}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

end
