module V1
  class CurriculumUnits < Base
    guard_all!

    namespace :curriculum_units
    
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

    desc "Turmas da UC"
    params do
      requires :id, type: Integer, desc: "id é inteiro"
    end
    get ":id/groups", rabl: "groups/list" do
      @groups = CurriculumUnit.where(id: params[:id]).first.try(:groups) || []
    end

  end
end
