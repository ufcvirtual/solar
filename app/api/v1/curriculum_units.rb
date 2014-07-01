module V1
  class CurriculumUnits < Base
    namespace :curriculum_units

    guard_all!

    segment do
      before do
        @u_groups = current_user.groups.where(offer_id: Offer.currents.map(&:id))
        @curriculum_units = CurriculumUnit.joins(:groups).where(groups: {id: @u_groups.map(&:id)})
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
