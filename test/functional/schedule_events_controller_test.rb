require 'test_helper'

class ScheduleEventsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
  end


  test "criar evento" do
    # pode criar para qualquer opção do filtro: curso, uc, oferta ou turma.

    #turmas
    assert_difference(["ScheduleEvent.count", "Schedule.count"], 1) do
      assert_difference(["AcademicAllocation.count"], 3) do
        post :create, {allocation_tags_ids: "#{allocation_tags(:al3).id} #{allocation_tags(:al11).id} #{allocation_tags(:al22).id}", schedule_event: {title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: "Polo A", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
      end
    end

    assert_equal I18n.t(:created, scope: [:schedule_events, :success]), get_json_response("notice")
    assert_response :success

    # oferta
    assert_difference(["ScheduleEvent.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, {allocation_tags_ids: "#{allocation_tags(:al6).id}", schedule_event: {title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: "Polo A", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_equal I18n.t(:created, scope: [:schedule_events, :success]), get_json_response("notice")
    assert_response :success

    # uc
    assert_difference(["ScheduleEvent.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, {allocation_tags_ids: "#{allocation_tags(:al13).id}", schedule_event: {title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: "Polo A", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_equal I18n.t(:created, scope: [:schedule_events, :success]), get_json_response("notice")
    assert_response :success

    # curso
    assert_difference(["ScheduleEvent.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, {allocation_tags_ids: "#{allocation_tags(:al19).id}", schedule_event: {title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: "Polo A", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_equal I18n.t(:created, scope: [:schedule_events, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao criar evento - sem permissao" do
    sign_in users(:aluno1)

    assert_no_difference(["ScheduleEvent.count", "Schedule.count", "AcademicAllocation.count"]) do
      post :create, {allocation_tags_ids: "#{allocation_tags(:al3).id} #{allocation_tags(:al11).id} #{allocation_tags(:al22).id}", schedule_event: {title: "Prova", type_event: Presential_Test, start_hour: "10:30", end_hour: "11:30", place: "Polo A", schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_response :redirect
    assert_redirected_to home_path
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "editar evento" do
    assert_no_difference(["ScheduleEvent.count", "AcademicAllocation.count"]) do
      put(:update, {id: schedule_events(:presential_test1).id, schedule_event: {title: "Prova"}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    assert_equal "Prova", ScheduleEvent.find(schedule_events(:presential_test1).id).title
    assert_equal I18n.t(:updated, scope: [:schedule_events, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao editar evento - sem permissao" do
    sign_in users(:aluno1)

    assert_no_difference(["ScheduleEvent.count", "AcademicAllocation.count"]) do
      put(:update, {id: schedule_events(:presential_test1).id, schedule_event: {title: "Prova"}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    assert_not_equal "Prova", ScheduleEvent.find(schedule_events(:presential_test1).id).title
    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "deletar um evento" do
    assert_difference(["ScheduleEvent.count", "AcademicAllocation.count"], -1) do
      delete(:destroy, {id: schedule_events(:presential_test1).id, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    assert_equal I18n.t(:deleted, scope: [:schedule_events, :success]), get_json_response("notice")
    assert_response :success
  end

  test "nao deletar um evento - sem permissao" do
    sign_in users(:aluno1)

    assert_no_difference(["ScheduleEvent.count", "AcademicAllocation.count"]) do
      delete(:destroy, {id: schedule_events(:presential_test1).id, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end
    
    assert_response :unauthorized
    assert_equal get_json_response("alert"), I18n.t(:no_permission)
  end

  test "edicao - ver detalhes" do
    get(:show, {id: schedule_events(:presential_test1).id, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    assert_template :show
  end

  test "edicao - ver detalhes - aluno" do
    sign_in users(:aluno1)
    get(:show, {id: schedule_events(:presential_test1).id, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    assert_template :show
  end

end