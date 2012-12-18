require 'test_helper'

class OffersControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    @editor = users(:editor)
    sign_in @editor
  end



  ##
  # Index
  ##

  # Usuário com permissão e acesso
  test "lista ofertas a partir de uc e curso" do 
    get :index, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_response :success
    assert_not_nil assigns(:course_id)
    assert_not_nil assigns(:curriculum_unit_id)
    assert_not_nil assigns(:offers)
    assert_not_nil assigns(:courses)
    assert_not_nil assigns(:curriculum_units)
    assert_template :index
  end

  # Usuário com permissão e sem acesso
  test "nao lista ofertas a partir de uc e curso - sem acesso" do 
    get :index, {:course_id => courses(:c1).id, :curriculum_unit_id => curriculum_units(:r1)}
    assert_response :redirect
    assert_not_nil assigns(:course_id)
    assert_not_nil assigns(:curriculum_unit_id)
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Usuário sem permissão 
  test "nao lista ofertas a partir de uc e curso - sem permissao" do 
    sign_out @editor
    sign_in users(:professor)
    get :index, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_response :redirect
    assert_not_nil assigns(:course_id)
    assert_not_nil assigns(:curriculum_unit_id)
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # New/Create
  ##

  # Usuário com permissão e acesso
  test "criar ofertas" do
    get :index, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    offers_to_create = assigns(:courses).size * assigns(:curriculum_units).size
    get :new, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_template :new
    assert_difference("Offer.count", +offers_to_create) do 
      post :create, {:offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id }
      assert_not_nil assigns(:courses)
      assert_not_nil assigns(:curriculum_units)
    end
    assert_response :success
    assert_template :index
  end

  # Usuário com permissão e sem acesso
  test "nao criar ofertas - sem acesso" do
    get :new, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_template :new
    assert_no_difference("Offer.count") do 
      post :create, {:offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :course_id => courses(:c1).id, :curriculum_unit_id => curriculum_units(:r5).id }
      assert_not_nil assigns(:courses)
      assert_not_nil assigns(:curriculum_units)
    end
    assert_template :index
    assert_response :error
  end

  # Usuário sem permissão 
  test "nao criar ofertas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)
    get :new, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )

    assert_no_difference("Offer.count") do 
      post :create, {:offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r5).id }
      assert_not_nil assigns(:courses)
      assert_not_nil assigns(:curriculum_units)
    end

    assert_response :error
    assert_template :index
  end

  ##
  # Edit/Update
  ##

  # Usuário com permissão e acesso
  test "editar ofertas" do
    get :edit, {:id => offers(:of3).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_template :edit
    put :update, {:id => offers(:of3).id, :offer => {:semester => "1999.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id }
    assert_not_nil assigns(:courses)
    assert_not_nil assigns(:curriculum_units)
    assert_template :index
    assert_response :success
    assert_tag :tr, 
      :attributes => {:id => "#{offers(:of3).id}"},
      :child => {
        :tag => "td", 
        :content => "1999.2"
      }
  end

  # Usuário com permissão e sem acesso
  test "nao editar ofertas - sem acesso" do
    sign_out @editor
    sign_in users(:coorddisc)

    post :update, {:id => offers(:of3).id, :offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :course_id => courses(:c1).id, :curriculum_unit_id => curriculum_units(:r5).id }
    assert_response :error

    sign_in @editor
    get :index, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_no_tag :tr, 
      :attributes => {:id => "#{offers(:of3).id}"},
      :child => {
        :tag => "td", 
        :content => "1900.2"
      }
  end

  # Usuário sem permissão 
  test "nao editar ofertas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)

    get :edit, {:id => offers(:of3).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_redirected_to({:controller => :home})
    assert_equal( flash[:alert], I18n.t(:no_permission) )

    post :update, {:id => offers(:of3).id, :offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :course_id => courses(:c1).id, :curriculum_unit_id => curriculum_units(:r5).id }
    assert_response :error
  end

  ##
  # Destroy
  ##

  # Usuário com permissão e acesso
  test "remover oferta" do 
    assert_difference("Offer.count", -1) do 
      get(:destroy, {:id => offers(:of7).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id})
    end
    assert_template :index
    assert_response :success
  end

  # Usuário com permissão e acesso, mas a oferta não permite
  test "nao remove oferta - niveis inferiores" do
    assert_no_difference("Offer.count") do 
      get :destroy, {:id => offers(:of3).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    end
    assert_template :index
    assert_response :error
  end

  # Usuário com permissão e sem acesso
  test "nao remove oferta - sem acesso" do
    assert_no_difference("Offer.count") do 
      get :destroy, {:id => offers(:of4).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r4).id}
    end
    assert_template :index
    assert_response :error
  end

  # Usuário sem permissão 
  test "nao remove oferta - sem permissao" do
    sign_out @editor
    sign_in users(:professor)
    assert_no_difference("Offer.count") do 
      get :destroy, {:id => offers(:of3).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    end
    assert_template :index
    assert_response :error
  end

  ##
  # Deactivate_groups
  ##

  # Usuário com permissão e acesso
  test "desativar todas as turmas" do
    get :index, {:course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_template :index
    assert_tag :button, 
      :attributes => {
        :id => "deactivate_groups_"+offers(:of3).id.to_s, 
        :class => "btn btn_caution deactivate_groups"
      }
    post :deactivate_groups, {:id => offers(:of3).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_template :index
    assert_equal offers(:of3).groups, offers(:of3).groups.where(:status => false)
    assert_tag :button, 
      :attributes => {
        :id => "deactivate_groups_"+offers(:of3).id.to_s, 
        :class => "btn btn_disabled deactivate_groups"
      }

    assert_response :success
  end

  # Usuário com permissão e sem acesso
  test "nao desativar todas as turmas - sem acesso" do
    post :deactivate_groups, {:id => offers(:of4).id, :course_id => courses(:c1).id, :curriculum_unit_id => curriculum_units(:r4).id}
    assert_not_equal offers(:of4).groups, offers(:of4).groups.where(:status => false)
    assert_response :error
  end

  # Usuário sem permissão 
  test "nao desativar todas as turmas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)
    post :deactivate_groups, {:id => offers(:of3).id, :course_id => courses(:c2).id, :curriculum_unit_id => curriculum_units(:r3).id}
    assert_not_equal offers(:of3).groups, offers(:of3).groups.where(:status => false)
    assert_response :error
  end

end
