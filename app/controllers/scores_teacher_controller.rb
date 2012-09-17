class ScoresTeacherController < ApplicationController

  before_filter :prepare_for_pagination, :only => [:list]
  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, ScoresTeacher #verifica se pode acessar método

    curriculum_unit_id = active_tab[:url]['id']
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    @group = Group.joins(:allocation_tag).where("allocation_tags.id = ?", allocation_tag_id).first

    authorize! :list, @group.allocation_tag #verifica se pode acessar turma

    unless @group.nil?
      @assignments = Assignment.all(:joins => [:allocation_tag, :schedule], :conditions => ["allocation_tags.group_id = 
        #{@group.id}"], :select => ["assignments.id", "schedule_id", "type_assignment", "name"]) #assignments da turma
      students_ids = Allocation.all(:select => :user_id, :joins => [:allocation_tag, :profile], :conditions => ["
        allocation_tags.group_id = #{@group.id} AND allocations.status = #{Allocation_Activated} AND 
        cast(profiles.types & #{Profile_Type_Student} as boolean)"]).map(&:user_id) 
      @students = User.select("name, id").find(students_ids) #alunos da turma
      @scores = ScoresTeacher.students_information(@students, @assignments, curriculum_unit_id, allocation_tag_id) #dados dos alunos nas atividades
    end
  end
  
end
