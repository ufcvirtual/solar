require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

	fixtures :allocation_tags, :assignments, :group_assignments
  include Devise::TestHelpers


  ##
  # List
  ##

	test "listar as atividiades de uma turma para usuario com permissao" do 
		sign_in users(:professor)
		get :list
		assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
	end

	test "nao listar as atividiades de uma turma para usuario sem permissao" do 
		sign_in users(:aluno1)
		get :list
		assert_response :redirect
	end

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC
# tentar fazer get com url: http://localhost:3000/application/add_tab/4?allocation_tag_id=15&context=2&name=Introdu%C3%A7%C3%A3o+%C3%80s+Metodologias+%C3%81geis

	##
	# List_to_student
	##

	# test 'listar as atividades de um aluno para usuario com permissao' do 
	# 	sign_in users(:aluno1)
	# 	# get(:)
	# 	get(:list_to_student, {:allocation_tag_id => allocation_tags(:al3)})
	# 	assert_response :success
 #    assert_not_nil assigns(:individual_activities)
 #    assert_not_nil assigns(:group_activities)
	# end

	# test 'listar as atividades de um aluno para usuario sem permissao' do 
	# 	sign_in users(:professor)
	# 	get :list_to_student
	# 	assert_response :redirect
	# end

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC
	
	##
	# Information
	##

	# Perfil com permissao e usuario com acesso a atividade
	test "exibir informacoes da atividade individual para usuario com permissao" do
		sign_in users(:professor)
		get(:information, {:id => assignments(:a9).id})		
		assert_response :success
    assert_not_nil assigns(:assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_not_nil assigns(:students)
    assert_nil assigns(:groups)
    assert_nil assigns(:students_without_group)
	end

	# Perfil com permissao e usuario com acesso a atividade
	test "exibir informacoes da atividade em grupo para usuario com permissao" do
		sign_in users(:professor)
		get(:information, {:id => assignments(:a6).id})		
		assert_response :success
    assert_not_nil assigns(:assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_nil assigns(:students)
    assert_not_nil assigns(:groups)
    assert_not_nil assigns(:students_without_group)
	end

	# Perfil sem permissao e usuario com acesso a atividade
	test "nao exibir informacoes da atividade individual para usuario sem permissao" do
		sign_in users(:aluno1)
		get(:information, {:id => assignments(:a9).id})		
		assert_response :redirect
	end

	# Perfil sem permissao e usuario com acesso a atividade
	test "nao exibir informacoes da atividade em grupo para usuario sem permissao" do
		sign_in users(:aluno1)
		get(:information, {:id => assignments(:a6).id})		
		assert_response :redirect
	end

	# Perfil com permissao e usuario sem acesso a atividade
	test "nao exibir informacoes da atividade individual para usuario com permissao e sem acesso" do
		sign_in users(:professor)
		get(:information, {:id => assignments(:a10).id})		
		assert_response :redirect
	end

	# Perfil com permissao e usuario sem acesso a atividade
	test "nao exibir informacoes da atividade em grupo para usuario com permissao e sem acesso" do
		sign_in users(:professor)
		get(:information, {:id => assignments(:a11).id})		
		assert_response :redirect
	end

	##
	# Manage_groups
	##

	##
	# Show
	##

	# Perfil com permissao e usuario com acesso a atividade
	test "exibir pagina de avaliacao da atividade individual para usuario com permissao" do
		sign_in users(:professor)
		get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})
		assert_response :success
    assert_not_nil assigns(:student_id)
    assert_nil assigns(:group_id)
    assert_nil assigns(:group)
    assert_not_nil assigns(:send_assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_not_nil assigns(:send_assignment_files)
    assert_not_nil assigns(:comments)
	end

	# Perfil com permissao e usuario com acesso a atividade
	test "exibir pagina de avaliacao da atividade em grupo para usuario com permissao" do
		sign_in users(:professor)
		get(:show, {:id => assignments(:a6).id, :student_id => users(:aluno1).id, :group_id => group_assignments(:ga6).id})
		assert_response :success
    assert_nil assigns(:student_id)
    assert_not_nil assigns(:group_id)
    assert_not_nil assigns(:group)
    assert_nil assigns(:send_assignment)
    assert_not_nil assigns(:assignment_enunciation_files)
    assert_nil assigns(:send_assignment_files)
    assert_nil assigns(:comments)
	end

	# Perfil com permissao e usuario sem acesso a atividade
	test "nao exibir pagina de avaliacao da atividade individual para usuario com permissao e sem acesso" do
		sign_in users(:aluno2)
		get(:show, {:id => assignments(:a9).id}, :student_id => users(:aluno1).id)		
		assert_response :redirect
	end

	# Perfil com permissao e usuario sem acesso a atividade
	test "nao exibir pagina de avaliacao da atividade em grupo para usuario com permissao e sem acesso" do
		sign_in users(:aluno2)
		get(:show, {:id => assignments(:a6).id, :student_id => users(:aluno2).id, :group_id => group_assignments(:ga6).id})		
		assert_response :redirect
	end


	##
	# Evaluate
	#

	# Perfil com permissao e usuario com acesso
	test "permitir avaliar atividade individual para usuario com permissao" do
		sign_in users(:professor)
		post(:evaluate, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :grade => 7, :comment => "parabens, aluno."})
		assert_response :success
	end

	# Perfil com permissao e usuario sem acesso
	test "permitir avaliar atividade individual para usuario com permissao e sem acesso" do
		sign_in users(:professor)
		post(:evaluate, {:id => assignments(:a10).id, :student_id => users(:aluno1).id, :grade => 7, :comment => "parabens, aluno."})
		assert_response :redirect
	end

	# Perfil sem permissao e usuario com acesso
	test "permitir avaliar atividade individual para usuario sem permissao e com acesso" do
		sign_in users(:aluno1)
		post(:evaluate, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :grade => 7, :comment => "parabens, aluno."})
		assert_response :redirect
	end

	##
	# Send_comment
	##

	# Novo comentário
############## Cannot redirect to nil! => REDIRECT_TO REQUEST.REFERER
	# Perfil com permissao e usuario com acesso
	test "permitir comentar em atividade individual para usuario com permissao" do
		sign_in users(:professor)
		get(:show, {:id => assignments(:a9).id, :student_id => users(:aluno1).id})
		# assert_response :success
		post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
		# assert_response :success
		# assert_response 302
		# assert_redirected_to(:controller => :assignments, :action => :show)
	end

	# # Perfil com permissao e usuario sem acesso
	# test "permitir comentar em atividade individual para usuario com permissao e sem acesso" do
	# 	sign_in users(:professor)
	# 	post(:send_comment, {:id => assignments(:a10).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
	# 	assert_response :redirect
	# end

	# # Perfil sem permissao e usuario com acesso
	# test "permitir comentar em atividade individual para usuario sem permissao e com acesso" do
	# 	sign_in users(:aluno1)
	# 	post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
	# 	assert_response :redirect
	# end

	# Editar comentário
	
	# # Perfil com permissao e usuario com acesso
	# test "permitir avaliar atividade individual para usuario com permissao" do
	# 	sign_in users(:professor)
	# 	post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
	# 	assert_response :success
	# end

	# # Perfil com permissao e usuario sem acesso
	# test "permitir avaliar atividade individual para usuario com permissao e sem acesso" do
	# 	sign_in users(:professor)
	# 	post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
	# 	assert_response :redirect
	# end

	# # Perfil sem permissao e usuario com acesso
	# test "permitir avaliar atividade individual para usuario sem permissao e com acesso" do
	# 	sign_in users(:aluno1)
	# 	post(:send_comment, {:id => assignments(:a9).id, :student_id => users(:aluno1).id, :comment => "bom trabalho."})
	# 	assert_response :redirect
	# end

	##
	# Remove_comment
	##

	##
	# Download_files
	##

	##
	# Send_public_files_page
	##

	##
	# Upload_file
	##

	##
	# Delete_file
	##

	##
	# Import_groups_page
	##

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC
# tentar fazer get com url: http://localhost:3000/application/add_tab/4?allocation_tag_id=15&context=2&name=Introdu%C3%A7%C3%A3o+%C3%80s+Metodologias+%C3%81geis

	# # Perfil com permissao e usuario com acesso a atividade
	# test 'exibir pagina de importacao de grupos entre atividades para usuario com permissao' do
	# 	sign_in users(:professor)
	# 	get(:import_groups_page, {:id => assignments(:a6).id})		
	# 	assert_response :success
 #    assert_not_nil assigns(:assignments)
	# end

	# # Perfil sem permissao e usuario com acesso a atividade
	# test 'exibir pagina de importacao de grupos entre atividades para usuario sem permissao' do
	# 	sign_in users(:aluno1)
	# 	get(:import_groups_page, {:id => assignments(:a6).id})		
	# 	assert_response :redirect
	# end

	# # Perfil com permissao e usuario sem acesso a atividade
	# test 'exibir pagina de importacao de grupos entre atividades para usuario com permissao e sem acesso' do
	# 	sign_in users(:professor)
	# 	get(:import_groups_page, {:id => assignments(:a11).id})		
	# 	assert_response :redirect
	# end

### ALLOCATION_TAG É PASSADA PELO 'ADD_TAB' QUANDO CLICA NA UC

	##
	# Import_groups
	##


end
