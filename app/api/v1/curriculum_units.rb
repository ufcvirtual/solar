module V1
  class CurriculumUnits < Base
    namespace :curriculum_units

    guard_all!

    get "/", rabl: "curriculum_units/list" do # Retorna UCs da oferta vigente. Futuramente, poderemos especificar outra oferta
      @curriculum_units = Semester.all_by_period.map(&:offers).flatten.map(&:curriculum_unit)
    end

    get "groups", rabl: "curriculum_units/list_with_groups" do # Retorna todas as UCs da oferta vigente incluindo as turmas
      @curriculum_units = Semester.all_by_period.map(&:offers).flatten.map(&:curriculum_unit)
    end

    get ":id/groups", rabl: "groups/list" do # Retorna as turmas da UC
      @groups = CurriculumUnit.find(params[:id]).groups
    end

  end
end
