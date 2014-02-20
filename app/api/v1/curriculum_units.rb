module V1
  class CurriculumUnits < Base
    namespace :curriculum_units

    guard_all!

    segment do
      before do
        @curriculum_units = Semester.all_by_period.map(&:offers).flatten.map(&:curriculum_unit) # atual
      end

      desc "Lista UCs da oferta vigente."
      get "/", rabl: "curriculum_units/list" do # Futuramente, poderemos especificar outra oferta
        # @curriculum_units
      end

      desc "Lista UCs da oferta vigente incluindo as turmas"
      get "groups", rabl: "curriculum_units/list_with_groups" do
        # @curriculum_units
      end
    end

  end
end
