module V1
  class CurriculumUnits < Base
    namespace :curriculum_units

    segment do
      before do
        guard!
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

    ## curriculum_unit/load/editors
    namespace :load do
      post :editors do
        verify_ip_access!

        load_editors  = params[:load_editors]
        uc            = CurriculumUnit.find_by_code!(load_editors[:codDisciplina])
        users         = User.where(cpf: load_editors[:editors])
        prof_editor   = 5

        begin
          users.each do |user|
            uc.allocate_user(user.id, prof_editor)
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end
  end
end
