module V1
  class CurriculumUnits < Base
    namespace :curriculum_units

    guard_all!

    segment do
      before do
        user_groups    = current_user.groups(nil, Allocation_Activated).map(&:id)
        current_offers = Offer.currents(Date.today, true).pluck(:id)

        @u_groups         = Group.where(id: user_groups, offer_id: current_offers)
        @curriculum_units = CurriculumUnit.joins(:groups).where(groups: {id: @u_groups.map(&:id)}).uniq
      end

      desc "Lista UCs da oferta vigente."
      get "/", rabl: "curriculum_units/list" do # Futuramente, poderemos especificar outra oferta
        # @curriculum_units
      end

      desc "Lista UCs da oferta vigente incluindo as turmas"
      get "groups", rabl: "curriculum_units/list_with_groups" do
        # @curriculum_units, @u_groups
      end
    end

  end
end
