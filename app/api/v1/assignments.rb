module V1
  class Assignments < Base

    guard_all!

    namespace :assignments do
      
      desc "Listar trabalhos"
      params do
        requires :allocation_tag_id, type: Integer
      end
      get "/" , rabl: 'assignments/list' do
        @assignments = Assignment.joins(:schedule, academic_allocations: :allocation_tag).where(allocation_tags: {id: params[:allocation_tag_id].to_i})
      end
    
    end

  end
end