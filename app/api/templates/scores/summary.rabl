collection @users

node do |student|
  { 
    id: student.id,
    name: student.name,
    access_to_the_course: student.u_logs,
    frequency: @wh.nil? ? 0 : student.working_hours,
    faults: @wh.nil? ? nil : @wh.to_i - student.working_hours.to_i,
    partial_grade: student.partial_grade,
    af_grade: student.af_grade,
    final_grade: student.u_grade,
    situation: Allocation.status_name(student.grade_situation)
  }
end

