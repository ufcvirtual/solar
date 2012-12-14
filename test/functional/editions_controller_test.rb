require 'test_helper'

class EditionsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
  end

=begin
  test "exibir pagina de edicao" do
  	get :index
  	assert_not_nil assigns(:course_id)
  	assert_not_nil assigns(:curriculum_unit_id)
  	assert_not_nil assigns(:offer_id)
  	assert_not_nil assigns(:group_id)
  	assert_not_nil assigns(:allocation_tags_ids)
	end

	test "nao exibir pagina de edicao - sem permissao" do
		sign_in users(:professor)
  	get :index
  	assert_nil assigns(:course_id)
  	assert_nil assigns(:curriculum_unit_id)
  	assert_nil assigns(:offer_id)
  	assert_nil assigns(:group_id)
  	assert_nil assigns(:allocation_tags_ids)
	end
=end

end