module V1
  class Assignments < Base

    guard_all!

    namespace :assignments do
      
      desc "Listar todos trabalhos da turma"
      params do
        requires :allocation_tag_id, type: Integer
      end
      get "/" , rabl: 'assignments/list' do
        @assignments = Assignment.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: params[:allocation_tag_id].to_i})
      end
      
      
      desc "Listar informações de trabalhos individuais do aluno"
      params do
        requires :student_id, type: Integer
        requires :allocation_tag_id, type: Integer
      end
      get "/:student_id/individual" , rabl: 'assignments/info' do
        ac = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i, academic_tool_type: 'Assignment')
        @acus = AcademicAllocationUser.where(user_id: params[:student_id].to_i).where(academic_allocation_id: ac.map(&:id))
        # @assignments_indiv = Score.list_tool(params[:student_id], params[:allocation_tag_id], 'assignments', false, false, true, false, Assignment_Type_Individual)
      end
    
    end

  end
end