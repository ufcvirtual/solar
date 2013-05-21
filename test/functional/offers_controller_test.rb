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
  test "lista ofertas" do 
    get :index, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]
    assert_response :success
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:offers)
  end

  # Usuário com permissão e sem acesso
  test "nao lista ofertas - sem acesso" do 
    get :index, allocation_tags_ids: [allocation_tags(:al5).id]
    assert_response :redirect
    assert_not_nil assigns(:allocation_tags_ids)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Usuário sem permissão 
  test "nao lista ofertas - sem permissao" do 
    sign_out @editor
    sign_in users(:professor)
    get :index, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]
    assert_response :redirect
    assert_not_nil assigns(:allocation_tags_ids)
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # New/Create
  ##

  # Usuário com permissão e acesso
  test "criar ofertas" do
    get :index, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]
    get :new, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]
    assert_template :new
    assert_difference("Offer.count", +1) do 
      post :create, {:offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :enroll_start => "2012-12-01", allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id] }
    end
    assert_response :redirect
  end

  # Usuário com permissão e sem acesso
  test "nao criar ofertas - sem acesso" do
    get :new, allocation_tags_ids: [allocation_tags(:al5).id]
    assert_response :redirect

    assert_no_difference("Offer.count") do 
      post :create, {:offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :enroll_start => "2012-12-01", allocation_tags_ids: [allocation_tags(:al5).id] }
    end
    assert_response :error
    assert_template :index
  end

  # Usuário sem permissão 
  test "nao criar ofertas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)
    get :new, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]
    assert_response :redirect
    
    assert_no_difference("Offer.count") do 
      post :create, {:offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :enroll_start => "2012-12-01", allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id] }
    end
    assert_response :error
    assert_template :index
  end

  ##
  # Edit/Update
  ##

  # Usuário com permissão e acesso
  test "editar ofertas" do
    get :edit, {:id => offers(:of3).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    assert_template :edit
    put :update, {:id => offers(:of3).id, :offer => {:semester => "1999.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :enroll_start => "2012-12-01", allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    assert_not_nil assigns(:allocation_tags_ids)
    assert_response :redirect
    assert_equal Offer.find(offers(:of3).id).semester, "1999.2"
  end

  # Usuário com permissão e sem acesso
  test "nao editar ofertas - sem acesso" do
    post :update, {:id => offers(:of2).id, :offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :enroll_start => "2012-12-01", allocation_tags_ids: [allocation_tags(:al5).id]}
    assert_response :error
    assert_template :index
    assert_not_equal Offer.find(offers(:of2).id).semester, "1900.2"
  end

  # Usuário sem permissão 
  test "nao editar ofertas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)

    get :edit, {:id => offers(:of3).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )

    post :update, {:id => offers(:of3).id, :offer => {:semester => "1900.2", :start_date => "2012-12-01", :end_date => "2012-12-31"}, :enroll_start => "2012-12-01", allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    assert_response :error

    assert_not_equal Offer.find(offers(:of2).id).semester, "1900.2"
  end

  ##
  # Destroy
  ##

  # Usuário com permissão e acesso (remove seu respectivo módulo default, pois não possui aulas)
  test "remover oferta" do 
    assert_difference(["Offer.count", "LessonModule.count"], -1) do 
      get(:destroy, {:id => offers(:of7).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]})
    end

    assert_response :redirect
    assert_equal flash[:notice], I18n.t(:deleted_success, scope: :offers)
  end

  # Usuário com permissão e acesso, mas a oferta não permite (possui níveis inferiores)
  test "nao remove oferta - niveis inferiores" do
    assert_no_difference("Offer.count") do 
      get :destroy, {:id => offers(:of3).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:not_possible_to_delete, scope: :offers)
  end

  # Usuário com permissão e sem acesso
  test "nao remove oferta - sem acesso" do
    assert_no_difference("Offer.count") do 
      get :destroy, {:id => offers(:of2).id, allocation_tags_ids: [allocation_tags(:al5).id]}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  # Usuário sem permissão 
  test "nao remove oferta - sem permissao" do
    sign_out @editor
    sign_in users(:professor)
    assert_no_difference("Offer.count") do 
      get :destroy, {:id => offers(:of3).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    end

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  ##
  # Deactivate_groups
  ##

  # Usuário com permissão e acesso
  test "desativar todas as turmas" do
    get :index, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]
    assert_template :index
    assert_tag :button, 
      :attributes => {
        :id => "deactivate_groups_"+offers(:of3).id.to_s, 
        :class => "btn btn_caution deactivate_groups"
      }
    post :deactivate_groups, {:id => offers(:of3).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    assert_equal offers(:of3).groups, offers(:of3).groups.where(:status => false)

    assert_response :redirect
    assert_equal flash[:notice], I18n.t(:all_groups_deactivated, :scope => [:offers, :index])
  end

  # Usuário com permissão e sem acesso
  test "nao desativar todas as turmas - sem acesso" do
    post :deactivate_groups, {:id => offers(:of4).id, allocation_tags_ids: [allocation_tags(:al15).id]}
    assert_not_equal offers(:of4).groups, offers(:of4).groups.where(:status => false)

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  # Usuário sem permissão 
  test "nao desativar todas as turmas - sem permissao" do
    sign_out @editor
    sign_in users(:professor)
    post :deactivate_groups, {:id => offers(:of3).id, allocation_tags_ids: [allocation_tags(:al6).id, allocation_tags(:al21).id]}
    assert_not_equal offers(:of3).groups, offers(:of3).groups.where(:status => false)

    assert_response :redirect
    assert_equal flash[:alert], I18n.t(:no_permission)
  end

end
