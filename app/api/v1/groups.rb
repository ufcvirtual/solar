module V1
  class Groups < Base
    guard_all!

    namespace :curriculum_units do
      desc "Turmas da UC"
      params do
        requires :id, type: Integer
      end
      get ":id/groups", rabl: "groups/list" do
        @groups = CurriculumUnit.where(id: params[:id]).first.try(:groups) || []
      end
    end

  end
end
