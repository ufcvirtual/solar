require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase

  fixtures :assignments, :users, :groups, :group_assignments

  test 'retorna o status da atividade de um aluno' do
  	assert_equal("not_sent", Assignment.assignment_situation_of_student(assignments(:a7).id, users(:aluno1).id))
  	assert_equal("sent", Assignment.assignment_situation_of_student(assignments(:a9).id, users(:aluno1).id))
  	assert_equal("corrected", Assignment.assignment_situation_of_student(assignments(:a3).id, users(:aluno1).id))
  	assert_equal("without_group", Assignment.assignment_situation_of_student(assignments(:a5).id, users(:aluno1).id))
  	assert_equal("send", Assignment.assignment_situation_of_student(assignments(:a9).id, users(:aluno2).id))
  	assert_equal("not_started", Assignment.assignment_situation_of_student(assignments(:a8).id, users(:aluno1).id))
  end

  test 'retorna se a atividade ja terminou seu prazo' do  	
  	assert assignments(:a7).closed?
  	assert not(assignments(:a2).closed?)
  end

  test 'retorna se o usuario tem tempo extra na atividade' do
  	assert assignments(:a7).extra_time?(users(:professor).id)
  	assert not(assignments(:a7).extra_time?(users(:aluno1).id))
  end

  test 'retorna alunos presentes em uma turma' do
  	allocation_tags = AllocationTag.find_related_ids(assignments(:a7).allocation_tag_id).join(',')
  	students_of_class_method = Assignment.list_students_by_allocations(allocation_tags)
  	students_of_class = Allocation.all(:include => [:allocation_tag, :user, :profile], :conditions => ["cast( profiles.types & '#{Profile_Type_Student}' as boolean) 
      AND allocations.status = #{Allocation_Activated} AND allocation_tags.group_id IS NOT NULL AND allocation_tags.id IN (#{allocation_tags})"]).map(&:user_id)
  	students_of_class = User.select("name, id").find(students_of_class)

  	assert_equal(students_of_class_method, students_of_class)
  end

  test 'informacoes das atividades que um aluno participa - atividades individuais' do
  	student_assignment_info = Assignment.student_assignments_info(groups(:g3).id, users(:aluno1).id, Individual_Activity)
  	
  	assignments_of_class = Assignment.all(:joins => [:allocation_tag, :schedule], :conditions => ["allocation_tags.group_id = #{groups(:g3).id} AND assignments.type_assignment = #{Individual_Activity}"],
     :select => ["assignments.id", "schedule_id", "name", "enunciation", "type_assignment"]) #atividades da turma do tipo escolhido
  	assert (student_assignment_info["assignments"] == assignments_of_class)

  	# a3: # quimica I - atividade III
  	assert (assignments_of_class.include?(assignments(:a3)))

  	student_group = (assignments(:a3).type_assignment == Group_Activity) ? (GroupAssignment.first(:include => [:group_participants], :conditions => ["group_participants.user_id = #{users(:aluno1).id} 
      AND group_assignments.assignment_id = #{assignments(:a3).id}"])) : nil #grupo do aluno
    user_id = (assignments(:a3).type_assignment == Group_Activity) ? nil : users(:aluno1).id #id do aluno
    assert_equal(user_id, users(:aluno1).id)

    group_id = (student_group.nil? ? nil : student_group.id) #se aluno estiver em grupo, recupera id
    assert_nil group_id

    send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(assignments(:a3), user_id, group_id) #atividade que tem send_assignment

    assignment_grade = send_assignment.nil? ? nil : send_assignment.grade #se tiver send_assignment, tenta pegar nota
    assert_equal(assignment_grade, 6.3)

    has_comments = send_assignment.nil? ? nil :  !(send_assignment.assignment_comments.empty? and send_assignment.comment.blank?) #verifica se há comentários para o aluno
		assert has_comments

    situation = Assignment.assignment_situation_of_student(assignments(:a3), users(:aluno1).id)
    assert_equal(situation, "corrected")
  end

  test 'informacoes das atividades que um aluno participa - atividades em grupo' do
  	student_assignment_info = Assignment.student_assignments_info(groups(:g3).id, users(:aluno1).id, Group_Activity)
  	
  	assignments_of_class = Assignment.all(:joins => [:allocation_tag, :schedule], :conditions => ["allocation_tags.group_id = #{groups(:g3).id} AND assignments.type_assignment = #{Group_Activity}"],
     :select => ["assignments.id", "schedule_id", "name", "enunciation", "type_assignment"]) #atividades da turma do tipo escolhido
  	assert (student_assignment_info["assignments"] == assignments_of_class)

  	# a6: # quimica I - Atividade em grupo III
  	assert (assignments_of_class.include?(assignments(:a6)))

  	student_group = (assignments(:a6).type_assignment == Group_Activity) ? (GroupAssignment.first(:include => [:group_participants], :conditions => ["group_participants.user_id = #{users(:aluno1).id} 
      AND group_assignments.assignment_id = #{assignments(:a6).id}"])) : nil #grupo do aluno
    user_id = (assignments(:a6).type_assignment == Group_Activity) ? nil : users(:aluno1).id #id do aluno
    assert_nil user_id

    group_id = (student_group.nil? ? nil : student_group.id) #se aluno estiver em grupo, recupera id
    assert_equal(group_id, group_assignments(:ga6).id)

    send_assignment = SendAssignment.find_by_assignment_id_and_user_id_and_group_assignment_id(assignments(:a6), user_id, group_id) #atividade que tem send_assignment

    assignment_grade = send_assignment.nil? ? nil : send_assignment.grade #se tiver send_assignment, tenta pegar nota
    assert_nil assignment_grade

    has_comments = send_assignment.nil? ? nil :  !(send_assignment.assignment_comments.empty? and send_assignment.comment.blank?) #verifica se há comentários para o aluno
		assert_nil has_comments

    situation = Assignment.assignment_situation_of_student(assignments(:a6), users(:aluno1).id)
    assert_equal(situation, "send")
  end

  test 'usuario nao pode acessar atividade que nao tem relacao' do
  	assert not(assignments(:a10).user_can_access_assignment(users(:aluno1).id, users(:aluno2).id))
  	assert assignments(:a9).user_can_access_assignment(users(:professor).id, users(:aluno1).id)
  end

end
