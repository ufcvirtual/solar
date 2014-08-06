require 'test_helper'

class AgendasControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor = users(:editor)
    sign_in @editor
  end

  test 'exibe calendario' do
    get :calendar, {selected: "group", allocation_tags_ids: "3 11 22"}

    assert_template :calendar
    assert_response :success

    get :events, {allocation_tags_ids: "3 11 22"}
    assert_not_nil assigns(:events)
  end

  test 'exibe calendario - aluno' do
    sign_in users(:aluno1)

    get :calendar, {selected: "group", allocation_tags_ids: "3"}
    assert_template :calendar
    assert_response :success

    get :events, {allocation_tags_ids: "3 11 22"}
    assert_nil assigns(:events)
    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)

    get :events, {allocation_tags_ids: "3"}
    assert_not_nil assigns(:events)
  end

end