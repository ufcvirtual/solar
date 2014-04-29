require 'test_helper'

class ScoreTest < ActiveSupport::TestCase

  # fixtures :assignments, :users, :groups, :group_assignments
  fixtures :all

  test "informacoes de todos os alunos para todas as atividades de uma turma" do
    assignments = Assignment.all(:joins => [{academic_allocations: :allocation_tag}, :schedule], :conditions => ["allocation_tags.group_id = 
        #{groups(:g3).id}"], :select => ["assignments.id", "schedule_id", "type_assignment", "name"]) #assignments da turma
    ats = AllocationTag.find_related_ids(allocation_tags(:al3).id).join(',')
    students = Assignment.list_students_by_allocations(ats)
    scores = Score.students_information(students, assignments, allocation_tags(:al3).group) #dados dos alunos nas atividades

    # a3: quimica I - atividade III
    aluno1_a3_grade = sent_assignments(:sa1).grade 
    assert_equal aluno1_a3_grade, scores["students_grades"][0][2]
    assert_nil scores["students_groups"][0][2] #atividade individual retorna nil

    # a5: quimica I - trabalho em grupo2
    aluno1_a5_group = sent_assignments(:sa2).group_assignment_id
    assert_equal aluno1_a5_group, scores["students_groups"][0][4]

    # uc3: quimica I
    aluno1_uc3_access = LogAccess.find_all_by_user_id_and_log_type_and_allocation_tag_id(users(:aluno1).id, 3, curriculum_units(:r3).allocation_tag.id).size #quantidade de acessos do aluno na unidade curricular
    assert_equal aluno1_uc3_access, scores["student_count_access"][0]

    # a3: quimica I - atividade III
    aluno1_a3_public_files = PublicFile.find_all_by_user_id_and_allocation_tag_id(users(:aluno1).id, allocation_tags(:al3).id).size #quantidade de arquivos públicos do aluno na turma
    assert_equal aluno1_a3_public_files, scores["student_count_public_files"][0]
  end

#   test "historico de acessos" do
#     # uc3: quimica I
#     history_method = Score.history_student_id_and_interval(curriculum_units(:r3).id, users(:aluno1).id, (Date.current-1), (Date.current+1))
#     query = <<SQL
#    SELECT t2.name               AS curriculum_unit_name,
#           t1.created_at         AS access_date
#      FROM logs                  AS t1
#      JOIN curriculum_units      AS t2 ON t2.id = t1.curriculum_unit_id
#      WHERE t2.id = #{curriculum_units(:r3).id}
#        AND t1.log_type = #{AccessLog::TYPE[:curriculum_unit_access]}
#        AND t1.user_id = #{users(:aluno1).id}
#        AND t1.created_at::date BETWEEN '#{(Date.current-1)}' AND '#{(Date.current+1)}'
#      ORDER BY t1.created_at DESC;
# SQL
#     history = ActiveRecord::Base.connection.select_all query
#     assert_equal history, history_method
#   end

  # test "quantidade de acessos de um usuario em uma unidade curricular" do
  #   amount_method = Score.find_amount_access_by_student_id_and_interval(curriculum_units(:r3).id, users(:aluno1).id, (Date.current-1), (Date.current+1))
  #   conditions = "user_id = #{users(:aluno1).id}
  #       AND curriculum_unit_id = #{curriculum_units(:r3).id}
  #       AND log_type = #{Log::TYPE[:curriculum_unit_access]}
  #       AND created_at::date BETWEEN '#{(Date.current-1)}' AND '#{(Date.current+1)}'"
  #   amount = Log.where(conditions).count
  #   assert_equal amount_method, amount
  # end

#   test "numero de estudantes por turma" do
#     number_students_method = Score.number_of_students_by_group_id(groups(:g3).id)
#     query = <<SQL
#   SELECT COUNT(DISTINCT t1.id)::int AS cnt
#      FROM users             AS t1
#      JOIN allocations       AS t2 ON t2.user_id = t1.id
#      JOIN allocation_tags   AS t3 ON t3.id = t2.allocation_tag_id
#      JOIN profiles          AS t4 ON t4.id = t2.profile_id
#     WHERE t3.group_id = #{groups(:g3).id}
#       AND cast(t4.types & '#{Profile_Type_Student}' as boolean)
#       AND t2.status = #{Allocation_Activated};
# SQL
#     number_students =  ActiveRecord::Base.connection.select_all query
#     assert_equal number_students_method, number_students.first["cnt"].to_i
#   end

end