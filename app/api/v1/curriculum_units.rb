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
      format :xml

      # <load_editors>
      #   <cod_curriculum_unit>RM404</cod_curriculum_unit>
      #   <editors type="array">
      #     <value>11016853521</value>
      #     <value>57215688798</value>
      #   </editors>
      # </load_editors>

      post :editors do
        # valid IPs
        raise ActiveRecord::RecordNotFound unless YAML::load(File.open('config/webserver.yml'))[Rails.env.to_s]['address'].include?(request.env['REMOTE_ADDR'])

        load_editors  = params[:load_editors]
        uc            = CurriculumUnit.find_by_code(load_editors[:cod_curriculum_unit])
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
