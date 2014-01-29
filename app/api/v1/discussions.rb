module V1
  class Discussions < Base
    guard_all!

    namespace :groups do
      desc "Lista de fóruns da turma"
      params do
        requires :id, type: Integer
      end
      get ":id/discussions", rabl: "discussions/list" do
        @discussions = Discussion.all_by_allocation_tags(AllocationTag.find_by_group_id(params[:id]).related)
      end
    end

  end
end
