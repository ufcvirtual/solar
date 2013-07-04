require 'test_helper'

class OffersControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor = users(:editor)
    sign_in @editor
  end

  ##
  # New/Create
  ##

  test "criar oferta no semestre 2013.1" do
    s = semesters(:s2013_1)

    get :new, semester_id: s.id
    assert_template :new

    c_quimica = courses(:c2)
    uc_quimica = curriculum_units(:r3)

    assert_difference("Offer.count", 1) do
      post :create, {offer: {course_id: c_quimica.id, curriculum_unit_id: uc_quimica.id, semester_id: s.id}}
    end
  end

  test "criar oferta no semestre 2013.1 com periodo de matricula diferente" do
    s = semesters(:s2013_1)

    get :new, semester_id: s.id
    assert_template :new

    c_quimica = courses(:c2)
    uc_quimica = curriculum_units(:r3)

    assert_difference(["Offer.count", "Schedule.count"], 1) do
      post :create, {offer: {course_id: c_quimica.id, curriculum_unit_id: uc_quimica.id, semester_id: s.id, enrollment_schedule_attributes: {start_date: Date.today}}}
    end
  end

  test "erro ao tentar criar oferta sem semestre" do
    c_quimica = courses(:c2)
    uc_quimica = curriculum_units(:r3)

    assert_no_difference("Offer.count") do
      post :create, {offer: {course_id: c_quimica.id, curriculum_unit_id: uc_quimica.id}}
    end

    assert_template :new
  end

  # neste caso, o usuário terá permissão à uc, mas não ao curso escolhidos
  test "criar oferta - acesso parcial" do
    s = semesters(:s2013_1)

    c_letras   = courses(:c1)
    uc_quimica = curriculum_units(:r3)

    assert_difference("Offer.count") do
      post :create, {offer: {course_id: c_letras.id, curriculum_unit_id: uc_quimica.id, semester_id: s.id}}
    end   
  end

  # neste caso, o usuário não terá permissão nem à uc, nem ao curso escolhidos
  test "nao criar oferta - sem acesso" do
    s = semesters(:s2013_1)

    c_letras    = courses(:c1)
    uc_int_ling = curriculum_units(:r1)

    assert_no_difference("Offer.count") do
      post :create, {offer: {course_id: c_letras.id, curriculum_unit_id: uc_int_ling.id, semester_id: s.id}, format: :json}
    end   
    assert_response :unauthorized
  end


  test "nao criar ofertas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)

    s = semesters(:s2013_1)

    get :new, semester_id: s.id, format: :json
    assert_response :unauthorized
  end

  # test "nao criar ofertas - periodo de matricula invalido" do
  #   s = semesters(:s2013_1)
  #   c_quimica = courses(:c2)
  #   uc_quimica = curriculum_units(:r3)

  #   assert_no_difference(["Offer.count", "Schedule.count"]) do
  #     post :create, {offer: {course_id: c_quimica.id, curriculum_unit_id: uc_quimica.id, semester_id: s.id}, enrollment_schedule: {start_date: s.period_schedule.end_date + 1.month}}
  #   end
  # end

  ##
  # Edit/Update
  ##

  test "editar oferta - modificar periodo de matricula" do
    offer_2011_1 = offers(:of3)

    get :edit, id: offer_2011_1.id
    assert_template :edit

    assert_no_difference("Schedule.count") do # schedule eh apenas modificada
      put :update, {id: offer_2011_1.id, offer: {enrollment_schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month, id: 31}}}
    end
  end

  test "editar oferta - modificar periodo da oferta" do
    offer_2011_1 = offers(:of3)

    get :edit, id: offer_2011_1.id
    assert_template :edit

    assert_nil offer_2011_1.period_schedule

    assert_difference("Schedule.count", 1) do # schedule criada
      put :update, {id: offer_2011_1.id, offer: {period_schedule_attributes: {start_date: Date.today, end_date: Date.today + 1.month}}}
    end

    assert_not_nil Offer.find(offer_2011_1.id).period_schedule
  end

  ##
  # Destroy
  ##

  # Usuário com permissão e acesso (remove seu respectivo módulo default, pois não possui aulas)
  test "remover oferta" do
    offer_2012_1 = offers(:of7)

    assert_difference(["Offer.count", "LessonModule.count"], -1) do # schedule compartilhada com semestre
      assert_difference("Schedule.count", -2) do
        delete :destroy, id: offer_2012_1.id
      end
    end

    assert_response :ok
    assert_equal flash[:notice], I18n.t(:deleted_success, scope: :offers)
  end

  test "remover oferta sem remover schedule" do
    offer_2010_1 = offers(:of9)

    assert_difference("Offer.count", -1) do # schedule compartilhada com semestre
      assert_no_difference("Schedule.count") do
        delete :destroy, id: offer_2010_1.id
      end
    end

    assert_response :ok
    assert_equal flash[:notice], I18n.t(:deleted_success, scope: :offers)
  end

  test "nao remove oferta - niveis inferiores" do
    offer_2011_1 = offers(:of3) # com dependencias

    assert_no_difference(["Offer.count", "Schedule.count"]) do
      delete :destroy, id: offer_2011_1.id
    end

    assert_response :unprocessable_entity
    assert_equal flash[:alert], I18n.t(:not_possible_to_delete, scope: :offers)
  end

  test "nao remove oferta - sem acesso" do
    offer_2011_1 = offers(:of2) # sem permissao nesta oferta

    assert_no_difference(["Offer.count", "Schedule.count"]) do
      delete :destroy, id: offer_2011_1.id, format: :json
    end

    assert_response :unauthorized
  end

  test "nao remove oferta - sem permissao" do
    sign_out @editor
    sign_in users(:professor)

    offer_2011_1 = offers(:of3) # com dependencias

    assert_no_difference(["Offer.count", "Schedule.count"]) do
      delete :destroy, id: offer_2011_1.id, format: :json
    end

    assert_response :unauthorized
  end

  ##
  # Deactivate_groups
  ##

  test "desativar todas as turmas" do
    offer_2011_1 = offers(:of3) # com dependencias

    post :deactivate_groups, id: offer_2011_1.id

    assert_equal offer_2011_1.groups.count, offer_2011_1.groups.where(status: false).count
    assert_equal flash[:notice], I18n.t(:all_groups_deactivated, :scope => [:offers, :index])
  end

  test "nao desativar todas as turmas - sem acesso" do
    post :deactivate_groups, id: offers(:of4).id, format: :json

    assert_response :unauthorized
    assert_not_equal offers(:of4).groups.count, offers(:of4).groups.where(status: false).count
  end

  test "nao desativar todas as turmas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)

    post :deactivate_groups, id: offers(:of3).id, format: :json

    assert_response :unauthorized
    assert_not_equal offers(:of3).groups.count, offers(:of3).groups.where(status: false).count
  end

end
