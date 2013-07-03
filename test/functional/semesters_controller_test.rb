require 'test_helper'

class SemestersControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor = users(:editor)
    sign_in @editor
  end

  # test "lista semestres" do
        
  # end

  test "cria semestre" do
    get :new 
    assert_template :new

    assert_difference("Semester.count", 1) do
      assert_difference("Schedule.count", 2) do
        post :create, semester: {name: "2018.1", offer_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}, enrollment_schedule_attributes: {start_date: Date.today - 1.month, end_date: Date.today + 1.month}}
      end
    end
  end

  test "edita semestre" do
    s2010_1 = semesters(:s2010_1)

    get :edit, id: s2010_1.id
    assert_template :edit

    assert_no_difference(["Semester.count", "Schedule.count"]) do
      put :update, { id: s2010_1.id, semester: {name: "2018.2"}}
    end
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

  # test "nao remove semestre  - ofertas dependentes" do
  #   s2010_1 = semesters(:s2010_1)

  #   assert_no_difference(["Semester.count", "Schedule.count"]) do
  #     delete :destroy, { id: s2010_1.id }
  #   end
  # end

  # erro: assert_response :unauthorized

end