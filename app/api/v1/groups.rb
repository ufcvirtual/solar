module V1
  class Groups < Base
    namespace :curriculum_units do

      guard_all!

      desc "Turmas de uma UC do usuario"
      params do
        requires :id, type: Integer
      end
      get ":id/groups", rabl: "groups/list" do
        user_groups    = current_user.groups(nil, Allocation_Activated).map(&:id)
        current_offers = Offer.currents(Date.today, true).pluck(:id)

        @groups = CurriculumUnit.find(params[:id]).groups.where(groups: {id: user_groups, offer_id: current_offers}) rescue []
      end
    end
  end
end
