require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase

  fixtures :assignments, :users, :groups, :group_assignments, :schedules, :allocation_tags

  test "retorna o status da atividade de um aluno" do
    assert_equal("not_sent", assignments(:a13).situation_of_student(users(:aluno1).id))
    assert_equal("sent", assignments(:a9).situation_of_student(users(:aluno1).id))
    assert_equal("corrected", assignments(:a3).situation_of_student(users(:aluno1).id))
    assert_equal("without_group", assignments(:a12).situation_of_student(users(:aluno3).id))
    assert_equal("send", assignments(:a9).situation_of_student(users(:aluno2).id))
    assert_equal("not_started", assignments(:a8).situation_of_student(users(:aluno1).id))
  end

  test "retorna se a atividade ja terminou seu prazo" do    
    assert assignments(:a7).closed?
    assert not(assignments(:a2).closed?)
  end

  test "retorna se o usuario tem tempo extra na atividade" do
    assert assignments(:a7).extra_time?(allocation_tags(:al3), users(:professor).id)
    assert not(assignments(:a7).extra_time?(allocation_tags(:al3), users(:aluno1).id))
  end

  test "retorna alunos presentes em uma turma" do
    allocation_tags          = AllocationTag.find_related_ids(assignments(:a7).academic_allocations.first.allocation_tag_id).join(',')
    students_of_class_method = Assignment.list_students_by_allocations(allocation_tags)
    students_of_class        = Allocation.all(:include => [:allocation_tag, :user, :profile], :conditions => ["cast( profiles.types & '#{Profile_Type_Student}' as boolean) 
      AND allocations.status = #{Allocation_Activated} AND allocation_tags.group_id IS NOT NULL AND allocation_tags.id IN (#{allocation_tags})"]).map(&:user_id)
    students_of_class        = User.select("name, id").find(students_of_class)

    assert_equal(students_of_class_method, students_of_class)
  end

  test "informacoes das atividades que um aluno participa - atividades individuais" do
    group3 = groups(:g3)
    aluno1 = users(:aluno1)
    assignment3 = assignments(:a3)

    student_assignment_info = Assignment.student_assignments_info(group3.id, aluno1.id, Assignment_Type_Individual)
    assignments_of_class = Assignment.select(["assignments.id", "schedule_id", "name", "enunciation", "type_assignment"]).joins(:academic_allocations, :schedule).where(type_assignment: Assignment_Type_Individual, academic_allocations: {allocation_tag_id: group3.allocation_tag.id}) # atividades da turma do tipo escolhido

    assert_equal student_assignment_info["assignments"].sort, assignments_of_class.sort

    # a3: # quimica I - atividade III
    assert (assignments_of_class.include?(assignment3))

    student_group = (assignment3.type_assignment == Assignment_Type_Group) ? (GroupAssignment.joins(:academic_allocation, :group_participants).where(academic_allocations: {allocation_tag_id: group3.allocation_tag.id}, group_participants: {user_id: aluno1.id}, academic_allocations: {academic_tool_id: assignment3.id}).first) : nil 
    user_id       = (assignment3.type_assignment == Assignment_Type_Group) ? nil : aluno1.id 
    assert_equal(user_id, aluno1.id)

    group_id      = (student_group.nil? ? nil : student_group.id) # se aluno estiver em grupo, recupera id
    assert_nil group_id

    sent_assignment  = SentAssignment.joins(:academic_allocation).where(user_id: user_id, group_assignment_id: group_id, academic_allocations: {academic_tool_id: assignment3.id}).first # atividade que tem sent_assignment

    assignment_grade = sent_assignment.nil? ? nil : sent_assignment.grade # se tiver sent_assignment, tenta pegar nota
    assert_equal(assignment_grade, 6.3)

    has_comments  = sent_assignment.nil? ? nil :  (not sent_assignment.assignment_comments.empty?) # verifica se há comentários para o aluno
    assert has_comments

    situation     = assignment3.situation_of_student(aluno1.id)
    assert_equal(situation, "corrected")
  end

  test "informacoes das atividades que um aluno participa - atividades em grupo" do
    group3 = groups(:g3)
    aluno1 = users(:aluno1)
    assignment6 = assignments(:a6)

    student_assignment_info = Assignment.student_assignments_info(group3.id, aluno1.id, Assignment_Type_Group)

    assignments_of_class = Assignment.select(["assignments.id", "schedule_id", "name", "enunciation", "type_assignment"]).joins(:academic_allocations, :schedule).where(type_assignment: Assignment_Type_Group, academic_allocations: {allocation_tag_id: group3.allocation_tag.id}) # atividades da turma do tipo escolhido

    assert (student_assignment_info["assignments"] == assignments_of_class)

    # a6: # quimica I - Atividade em grupo III
    assert (assignments_of_class.include?(assignment6))

    student_group = (assignment6.type_assignment == Assignment_Type_Group) ? (GroupAssignment.joins(:academic_allocation, :group_participants).where(academic_allocations: {allocation_tag_id: group3.allocation_tag.id}, group_participants: {user_id: aluno1.id}, academic_allocations: {academic_tool_id: assignment6.id}).first) : nil 
    user_id       = (assignment6.type_assignment == Assignment_Type_Group) ? nil : aluno1.id 
    assert_nil user_id

    group_id      = (student_group.nil? ? nil : student_group.id) # se aluno estiver em grupo, recupera id
    assert_equal(group_id, group_assignments(:ga6).id)

    sent_assignment  = SentAssignment.joins(:academic_allocation).where(user_id: user_id, group_assignment_id: group_id, academic_allocations: {academic_tool_id: assignment6.id}).first # atividade que tem sent_assignment

    assignment_grade = sent_assignment.nil? ? nil : sent_assignment.grade # se tiver sent_assignment, tenta pegar nota
    assert_nil assignment_grade

    has_comments = sent_assignment.nil? ? nil : (not sent_assignment.assignment_comments.empty?) # verifica se há comentários para o aluno
    assert_nil has_comments

    situation    = assignment6.situation_of_student(aluno1.id)
    assert_equal(situation, "send")
  end

  test "usuario nao pode acessar atividade que nao tem relacao" do
    assert not(assignments(:a10).user_can_access_assignment(allocation_tags(:al4), users(:aluno1).id, users(:aluno2).id))
    assert assignments(:a9).user_can_access_assignment(allocation_tags(:al3), users(:professor).id, users(:aluno1).id)
  end

  # test "data final de avaliacao deve ser igual ou maior do que a data final da atividade" do 
  #   assignment = Assignment.create(:end_evaluation_date => schedules(:schedule27).end_date - 3.month, :allocation_tag_id => allocation_tags(:al3).id, :schedule_id => schedules(:schedule27).id, :name => "assignment 1", :enunciation => "assignment 1", :type_assignment => Assignment_Type_Individual)

  #   assert not(assignment.valid?)
  #   assert_equal assignment.errors[:end_evaluation_date].first, I18n.t(:greater_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => schedules(:schedule27).end_date.to_date)
  # end

end
