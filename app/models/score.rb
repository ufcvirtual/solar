class Score # < ActiveRecord::Base

  def self.informations(user_id, at_id, related: nil)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)

    assignments    = Assignment.joins(:academic_allocations, :schedule).includes(sent_assignments: :assignment_comments)
                    .where(academic_allocations: { allocation_tag_id:  at.id })
                    .select("assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date")
                    .order("start_date") if at.is_student?(user_id)
    discussions    = Discussion.posts_count_by_user(user_id, at_id)
    history_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related || at.related).limit(5)
    public_files   = PublicFile.where(user_id: user_id, allocation_tag_id: at_id)

    exams          = ExamUser.joins("LEFT JOIN academic_allocations ON exam_users.academic_allocation_id = academic_allocations.id AND grade is not null")
                             .joins("LEFT JOIN exams ON exams.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Exam' AND exams.status=TRUE")
                             .joins("LEFT JOIN schedules ON exams.schedule_id = schedules.id")
                             .where(academic_allocations: {allocation_tag_id: at_id}, user_id: user_id)
                             .select("DISTINCT exam_users.id as id, exams.id as exam_id, exam_users.user_id, exams.name, exam_users.grade, schedule_id, to_char(schedules.start_date,'dd/mm/YYYY') as start_date, to_char(schedules.end_date,'dd/mm/YYYY') as end_date") 
                             .order('start_date')  
                        
    [assignments, discussions, exams, history_access, public_files]
  end

  def self.grade_exam(user_id, at_id)
    avg_grade = 'NaN'
    exams = ExamUser.joins("LEFT JOIN academic_allocations ON exam_users.academic_allocation_id = academic_allocations.id AND grade is not null")
            .joins("LEFT JOIN exams ON exams.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Exam' AND exams.status=TRUE")
            .where(academic_allocations: {allocation_tag_id: at_id}, user_id: user_id)
            .select("to_char(AVG(exam_users.grade),'99.99') AS avg_grade")
    exams.each do |ex|
        avg_grade = ex.avg_grade
    end    
    avg_grade
  end  

  def self.list_exams_stud(user_id, at_id)
    list_exams = ExamUser.joins("LEFT JOIN academic_allocations ON exam_users.academic_allocation_id = academic_allocations.id AND grade is not null")
                    .joins("LEFT JOIN exams ON exams.id = academic_allocations.academic_tool_id AND academic_allocations.academic_tool_type = 'Exam' AND exams.status=TRUE")
                    .joins("LEFT JOIN exam_user_attempts ON exam_user_attempts.exam_user_id = exam_users.id")
                    .joins("LEFT JOIN schedules ON exams.schedule_id = schedules.id")
                    .where(academic_allocations: {allocation_tag_id: at_id}, user_id: user_id)
                    .select("DISTINCT exams.id, exams.name, exam_users.grade AS grade_fin, exam_user_attempts.grade as grade, schedule_id, to_char(schedules.start_date,'dd/mm/YYYY') as start_date, to_char(schedules.end_date,'dd/mm/YYYY') as end_date") 
                    .order('exams.id')  
  end  

end
