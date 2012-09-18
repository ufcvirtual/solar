require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase

  fixtures :assignments, :users

  test 'retorna se a atividade ja terminou seu prazo' do  	
  	assert assignments(:a7).closed?
  	assert not(assignments(:a2).closed?)
  end

  test 'retorna se o usuario tem tempo extra na atividade' do
  	assert assignments(:a7).extra_time?(users(:professor).id)
  	assert not(assignments(:a7).extra_time?(users(:aluno1).id))
  end

  test 'retorna o status da atividade de um aluno' do
  	assert_equal("not_sent", Assignment.assignment_situation_of_student(assignments(:a7).id, users(:aluno1).id))
  	assert_equal("sent", Assignment.assignment_situation_of_student(assignments(:a9).id, users(:aluno1).id))
  	assert_equal("corrected", Assignment.assignment_situation_of_student(assignments(:a3).id, users(:aluno1).id))
  	assert_equal("without_group", Assignment.assignment_situation_of_student(assignments(:a5).id, users(:aluno1).id))
  	assert_equal("send", Assignment.assignment_situation_of_student(assignments(:a9).id, users(:aluno2).id))
  	assert_equal("not_started", Assignment.assignment_situation_of_student(assignments(:a8).id, users(:aluno1).id))
  end

  

end
