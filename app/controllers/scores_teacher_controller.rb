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
      allocation_tags = AllocationTag.find_related_ids(allocation_tag_id).join(',')
      @students = Assignment.list_students_by_allocations(allocation_tags)
      @scores = ScoresTeacher.students_information(@students, @assignments, curriculum_unit_id, allocation_tag_id) #dados dos alunos nas atividades
    end
  end
  
end
