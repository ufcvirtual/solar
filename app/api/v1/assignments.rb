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

      desc "Listar todas as informações de trabalhos do aluno"
      params do
        requires :student_id, type: Integer
        requires :allocation_tag_id, type: Integer
      end
      get "/:student_id/all" , rabl: 'assignments/info' do
        @student = User.find(params[:student_id].to_i)
        ac = AcademicAllocation.where(allocation_tag_id: params[:allocation_tag_id].to_i, academic_tool_type: 'Assignment')
        acus_indi = AcademicAllocationUser.where(user_id: params[:student_id].to_i).where(academic_allocation_id: ac.map(&:id))
        acus_groups = AcademicAllocationUser.where('group_assignment_id IS NOT NULL').where(academic_allocation_id: ac.map(&:id))
        @acus = acus_indi.concat(acus_groups)
      end
      
    end

  end
end