module V1
  class Groups < Base
    namespace :curriculum_units do
      desc "Turmas da UC"
      params do
        requires :id, type: Integer
      end
      get ":id/groups", rabl: "groups/list" do
        guard!
        @groups = CurriculumUnit.find(params[:id]).groups.where(groups: {id: current_user.groups.map(&:id), offer_id: Offer.currents.map(&:id)}) rescue []
      end
    end
  end
end
