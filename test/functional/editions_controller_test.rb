require 'test_helper'

class EditionsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
  end

  test "exibir pagina de edicao" do
    get :index
    assert_select "div", :attributes => {:class =>"placesNavPanel"}
    
    get :items, :allocation_tags_ids => [allocation_tags(:al12)] # uc
    assert_no_tag "a", :attributes => {:id => "discussion"}
    get :items, :allocation_tags_ids => [allocation_tags(:al2)] # turma
    assert_select "a", :attributes => {:id => "discussion"}

    assert_not_nil assigns(:selected_course)
    assert_not_nil assigns(:selected_offer)
    assert_not_nil assigns(:selected_group)
    assert_not_nil assigns(:allocation_tags_ids)
  end

	test "nao exibir pagina de edicao - sem permissao" do
		sign_in users(:professor)
  	get :index
  	assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
	end

end