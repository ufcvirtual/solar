require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)

    @params_without_schedule = {title: "Lorem ipsum dolor sit amet.", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit."}
    @params_with_schedule = @params_without_schedule.merge({schedule_attributes: {start_date: "2013-10-10", end_date: "2013-10-11"}})

    @quimica = allocation_tags(:al3).id
  end

  test "rotas" do
    ## apenas algumas rotas
    assert_routing({method: :get, path: "/notifications/list"}, {controller: "notifications", action: "list"})

    assert_routing({method: :put, path: "/notifications/1/unbind/group/1"}, {controller: "groups", action: "change_tool", tool_id: "1", id: "1", type: "unbind", tool_type: "Notification"})
    assert_routing({method: :put, path: "/notifications/1/remove/group/1"}, {controller: "groups", action: "change_tool", tool_id: "1", id: "1", type: "remove", tool_type: "Notification"})
    assert_routing({method: :put, path: "/notifications/1/add/group/1"}   , {controller: "groups", action: "change_tool", tool_id: "1", id: "1", type: "add"   , tool_type: "Notification"})
  end

  test "exibicao para alunos" do
    sign_in users(:aluno1)
    get :index

    assert_response :success
    assert_not_nil assigns(:notifications)


    get :show, id: notifications(:notification_group).id
    assert_response :success
    assert_not_nil assigns(:notification)
  end

  test "edicao - listar" do
    get :list, {allocation_tags_ids: "#{@quimica}"}

    assert_response :success
    assert_not_nil assigns(:notifications)
  end

  test "cadastrar" do
    assert_difference(["AcademicAllocation.count", "Notification.count"], 1) do
      post :create, {allocation_tags_ids: "#{@quimica}", notification: @params_with_schedule}
    end
  end

  test "nao cadastrar sem dados validos" do
    assert_no_difference(["AcademicAllocation.count", "Notification.count"]) do
      post :create, {allocation_tags_ids: "#{@quimica}", notification: @params_without_schedule}
    end

    assert_template :new
  end

  test "nao cadastrar sem as duas datas da schedule" do
    assert_no_difference(["AcademicAllocation.count", "Notification.count"]) do
      post :create, {allocation_tags_ids: "#{@quimica}", notification: @params_without_schedule.merge({schedule_attributes: {start_date: "2013-05-05"}})}
    end

    assert not(assigns(:notification).schedule.errors.as_json[:end_date].empty?)
    assert_template :new
  end

  test "atualizar" do
    assert_difference(["AcademicAllocation.count", "Notification.count"], 1) do
      post :create, {allocation_tags_ids: "#{@quimica}", notification: @params_with_schedule}
    end

    notification = Notification.last
    assert_equal "Lorem ipsum dolor sit amet.", notification.title

    assert_no_difference(["AcademicAllocation.count", "Bibliography.count"]) do
      put :update, {id: notification.id, allocation_tags_ids: "#{@quimica}", notification: {title: "another title"}}
    end

    assert_equal "another title", Notification.last.title
  end

  test "deletar" do
    assert_difference(["AcademicAllocation.count", "Notification.count"], 1) do
      post :create, {allocation_tags_ids: "#{@quimica}", notification: @params_with_schedule}
    end

    assert_difference(["AcademicAllocation.count", "Notification.count"], -1) do
      delete :destroy, {id: Notification.last.id, allocation_tags_ids: "#{@quimica}"}
    end
  end

end
