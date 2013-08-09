require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :allocation_tags, :assignments, :group_assignments, :users, :sent_assignments

  test "listar as atividiades de uma turma para usuario com permissao" do 
    sign_in users(:professor)
    get :professor
    assert_response :success
    assert_not_nil assigns(:individual_activities)
    assert_not_nil assigns(:group_activities)
    assert_template :professor
  end

  test "nao listar as atividiades de uma turma para usuario sem permissao" do 
    sign_in users(:aluno1)
    get :professor
    assert_response :redirect
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end
  
  ##
  # Manage_groups
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'permitir a gerenciamento de grupos para usuario com permissao' do
    sign_in users(:professor)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga6).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a6).id, :groups => groups_hash})
    assert_response :success
    assert_template :group_assignment_content_div
    assert_tag :tag => "div", 
      :attributes => { :id => "group_#{group_assignments(:ga6).id}" },
      :child => { 
        :tag => "ul",
        :child => {
          :tag => "li", :attributes => {:class => "student_#{users(:aluno2).id}"} 
        } #o aluno1 já existia no grupo, foi adicionado o aluno 2.
     } #logo, verifica se ele foi adicionado ao grupo (validação do método)
    #após ajax
    # assert_equal(flash[:notice], I18n.t(:management_success, :scope => [:assignment, :group_assignments]))
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test 'nao permitir o gerenciamento de grupos para usuario com permissao e sem acesso' do
    sign_in users(:professor)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga7).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a11).id, :groups => groups_hash})
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out users(:professor)

    # não está dando sign out
    sign_in users(:tutor_distancia)
    get(:information, {:id => assignments(:a11).id})  
    assert_no_tag :tag => "div", 
      :attributes => { :id => "group_#{group_assignments(:ga6).id}" },
      :child => { 
        :tag => "ul",
        :child => {
          :tag => "li", :attributes => {:class => "student_#{users(:aluno2).id}"} 
        } #o aluno1 já existia no grupo, foi tentado adicionar o aluno 2.
     } #logo, verifica se ele realmente não foi adicionado ao grupo (validação da permissão)
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test 'nao permitir o gerenciamento de grupos para usuario sem permissao e com acesso' do
    sign_in users(:aluno3)
    groups_hash = {"0"=>{"group_id"=>group_assignments(:ga7).id, "group_name"=>"grupo 1", "student_ids"=>"7 8"}, "1"=>{"group_id"=>"0", "group_name"=>"grupo 2", "student_ids"=>"9"}}
    post(:manage_groups, {:id => assignments(:a11).id, :groups => groups_hash})
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
    sign_out users(:professor)

    # não está dando sign out
    sign_in users(:tutor_distancia)
    get(:information, {:id => assignments(:a11).id})  
    assert_no_tag :tag => "div", 
      :attributes => { :id => "group_#{group_assignments(:ga6).id}" },
      :child => { 
        :tag => "ul",
        :child => {
          :tag => "li", :attributes => {:class => "student_#{users(:aluno2).id}"} 
        } #o aluno1 já existia no grupo, foi tentado adicionar o aluno 2.
     } #logo, verifica se ele realmente não foi adicionado ao grupo (validação da permissão)
  end 

  ##
  # Import_groups_page
  # => assignments_with_allocation_tag_test.rb
  ##

  ##
  # Import_groups
  ##

  # Perfil com permissao e usuario com acesso a atividade
  test 'permitir a importacao de grupos entre atividades para usuario com permissao' do
    sign_in users(:professor)
    post(:import_groups, {:id => assignments(:a6).id, :assignment_id_import_from => assignments(:a5).id})   
    assert_redirected_to(information_assignment_path(assignments(:a6)))
    assert_equal(flash[:notice], I18n.t(:import_success, :scope => [:assignment, :import_groups]))
  end

  # Perfil com permissao e usuario sem acesso a atividade
  test 'nao permitir a importacao de grupos entre atividades para usuario com permissao e sem acesso' do
    sign_in users(:professor)
    post(:import_groups, {:id => assignments(:a11).id, :assignment_id_import_from => assignments(:a12).id})   
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  # Perfil sem permissao e usuario com acesso a atividade
  test 'nao permitir a importacao de grupos entre atividades para usuario sem permissao' do
    sign_in users(:aluno3)
    post(:import_groups, {:id => assignments(:a11).id, :assignment_id_import_from => assignments(:a12).id})   
    assert_redirected_to(home_path)
    assert_equal( flash[:alert], I18n.t(:no_permission) )
  end

  ##
  # Edicao
  ##
=begin # Testes ou funcionalidades serão refeitos
  test "listar trabalhos para edicao" do
    sign_in users(:editor)
    get :list, {what_was_selected: %(false false false true), allocation_tags_ids: [allocation_tags(:al3).id]}
    assert_response :success
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:assignments)
  end

  test "criar trabalho individual para uma unica turma" do
    sign_in users(:editor)

    assert_difference("Assignment.count", 1) do
      assignment = {
        allocation_tags_ids: "#{allocation_tags(:al3).id}",
        assignment: {
          schedule_attributes: {
            start_date: Time.now.to_date.to_s,
            end_date: (Time.now + 2.months).to_date.to_s,
          },
          allocation_tag_id: [allocation_tags(:al3).group.id],
          name: 'trabalho 1',
          enunciation: 'enunciado do trabalho 1',
          type_assignment: Assignment_Type_Individual,
          end_evaluation_date: (Time.now + 3.months).to_date.to_s
        }
      }
      post(:create, assignment)
    end
    assert_response :success
  end

  test "criar trabalho em grupo para duas turmas" do
    sign_in users(:editor)

    allocation_tags_ids = [allocation_tags(:al3).id, allocation_tags(:al11).id]
    get :new, {allocation_tags_ids: allocation_tags_ids}
    assert_template :new

    assert_difference("Assignment.count", 2) do
      assignment = {
        allocation_tags_ids: allocation_tags_ids.join(" "),
        assignment: {
          schedule_attributes: {
            start_date: Time.now.to_date.to_s,
            end_date: (Time.now + 2.months).to_date.to_s,
          },
          allocation_tag_id: [allocation_tags(:al3).group.id, allocation_tags(:al11).group.id], # turmas de quimica
          name: 'trabalho 1',
          enunciation: 'enunciado do trabalho 1',
          type_assignment: Assignment_Type_Group,
          end_evaluation_date: (Time.now + 3.months).to_date.to_s
        }
      }
      post(:create, assignment)
    end
    assert_response :success
  end

  test "editar trabalho" do
    sign_in users(:editor)

    # atividade II de  quimica I
    get :edit, {id: assignments(:a2).id, allocation_tags_ids: [allocation_tags(:al3).id]}
    assert_template :edit
    assert_not_nil assigns(:assignment)
  end

  test "atualizar trabalho" do
    sign_in users(:editor)

    assert_equal "Atividade II", assignments(:a2).name
    assert_no_difference("Assignment.count") do
      put :update, {id: assignments(:a2).id, assignment: {name: "Trabalho II"}, allocation_tags_ids: [allocation_tags(:al3).id]}
    end
    assert_response :success
    assert_equal "Trabalho II", Assignment.find(assignments(:a2).id).name
  end

  test "deletar apenas um trabalho" do
    sign_in users(:editor)

    assert_difference("Assignment.count", -1) do
      delete(:destroy, {id: assignments(:a4).id, allocation_tags_ids: [allocation_tags(:al3).id]})
    end
  end

  test "deletar varios trabalhos" do
    sign_in users(:editor)
    assignments = allocation_tags(:al3).group.assignments.includes(:sent_assignments).where(sent_assignments: {id: nil})
    assert_difference("Assignment.count", -assignments.count) do
      delete(:destroy, {id: assignments.map(&:id), allocation_tags_ids: [allocation_tags(:al3).id]})
    end
  end
=end
end
