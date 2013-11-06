require 'test_helper'

class SemestersControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor = users(:editor)
    @professor = users(:professor)
    sign_in @editor
  end

  test "lista semestres" do
     get :index
     assert_template :index
     assert_not_nil assigns(:semesters)
  end

  test "lista semestres - sem permissao" do
     sign_in @professor
     get :index, format: :json
     assert_response :unauthorized
     assert_nil assigns(:semesters)
  end

  test "cria semestre" do
    get :new 
    assert_template :new

    assert_difference("Semester.count", 1) do
      assert_difference("Schedule.count", 2) do
        post :create, semester: {name: "2018.1", offer_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}, enrollment_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}}
      end
    end
  end

  test "nao cria semestre - sem permissao" do
    sign_in @professor

    get :new, format: :json
    assert_response :unauthorized

    assert_no_difference(["Semester.count", "Schedule.count"]) do
      post :create, { semester: {name: "2018.1", offer_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}, enrollment_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}}, format: :json}
    end
    assert_response :unauthorized
  end

  test "edita semestre" do
    s2010_1 = semesters(:s2010_1)

    get :edit, id: s2010_1.id
    assert_template :edit

    assert_no_difference(["Semester.count", "Schedule.count"]) do
      put :update, { id: s2010_1.id, semester: {name: "2018.2"}}
    end

    assert_equal Semester.find(s2010_1.id).name, "2018.2"
  end

  test "nao edita semestre - sem permissao" do
    sign_in @professor
    s2010_1 = semesters(:s2010_1)

    get :edit, {id: s2010_1.id, format: :json}
    assert_response :unauthorized
      
    assert_no_difference(["Semester.count", "Schedule.count"]) do
      put :update, { id: s2010_1.id, semester: {name: "2018.2"}, format: :json }
    end

    assert_not_equal Semester.find(s2010_1.id).name, "2018.2"
    assert_response :unauthorized
  end

  test "remove semestre" do
    post :create, semester: {name: "2018.1", offer_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}, enrollment_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}}

    s2018_1 = Semester.last

    assert_difference("Semester.count", -1) do
      assert_difference("Schedule.count", -2) do
        delete :destroy, { id: s2018_1.id }
      end
    end
  end

  test "nao remove semestre  - ofertas dependentes" do
    s2010_1 = semesters(:s2010_1)

    assert_no_difference(["Semester.count", "Schedule.count"]) do
      delete :destroy, { id: s2010_1.id }
    end
  end

  test "nao remove semestre  - sem permissao" do
    sign_in @professor
    s2010_1 = semesters(:s2010_1)

    assert_no_difference(["Semester.count", "Schedule.count"]) do
      delete :destroy, { id: s2010_1.id, format: :json }
    end
    
    assert_response :unauthorized
  end

end
