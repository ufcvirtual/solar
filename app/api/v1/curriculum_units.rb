module V1
  class CurriculumUnits < Base

    segment do
      before do
        guard!

        user_groups    = current_user.groups([], Allocation_Activated).pluck(:id)
        current_offers = Offer.currents({user_id: current_user.id})

        @u_groups         = Group.where(id: user_groups, offer_id: current_offers)
        @curriculum_units = CurriculumUnit.joins(:offers).where("offers.id IN (?)", current_offers).distinct.order(:name)
      end

      namespace :curriculum_units do

        desc "Lista UCs da oferta vigente", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        get "/", rabl: "curriculum_units/list" do # Futuramente, poderemos especificar outra oferta
          # @curriculum_units
        end

        desc "Lista UCs da oferta vigente incluindo as turmas", {
          headers: {
            "Authorization" => {
              description: "Token",
              required: true
            }
          }
        }
        get "groups", rabl: "curriculum_units/list_with_groups" do
          # @curriculum_units, @u_groups
        end

      end # curriculum_units

    end # segment

    segment do

      before { verify_ip_access_and_guard! }

      namespace :curriculum_unit do

        desc "Criação de disciplina", hidden: true
        params do
          requires :name, :code, type: String
          optional :curriculum_unit_type_id, type: Integer, default: 2#, values: -> { CurriculumUnitType.all.map(&:id) }
          optional :resume, :syllabus, :objectives, :prerequisites, :working_hours, :credits
          optional :update_if_exists, type: Boolean, default: false
        end
        post "/" do
          begin
            uc = unless params[:update_if_exists]
              # CurriculumUnit.create! curriculum_unit_params(params, true)
              new_uc = CurriculumUnit.new curriculum_unit_params(params, true)
              new_uc.api = true
              new_uc.save!
            else
              verify_or_create_curriculum_unit params
            end
            {id: uc.id, course_id: uc.course.try(:id)}
          end
        end

        desc "Edição de disciplina", hidden: true
        params do
          requires :id, type: Integer#, values: -> { CurriculumUnit.all.map(&:id) }
          optional :name, :code, type: String
          optional :curriculum_unit_type_id, type: Integer#, values: -> { CurriculumUnitType.all.map(&:id) }
          optional :resume, :syllabus, :objectives, :prerequisites, :working_hours, :credits
          at_least_one_of :code, :name, :resume, :syllabus, :objectives, :prerequisites, :working_hours, :credits
        end
        put ":id" do
          begin
            # CurriculumUnit.find(params[:id]).update_attributes! curriculum_unit_params(params)
            uc = CurriculumUnit.find(params[:id])
            uc.api = true
            uc.update_attributes! curriculum_unit_params(params)

            {ok: :ok}
          end
        end

        desc "Remover disciplina", hidden: true
        params do
          optional :id, type: Integer
          optional :code
          exactly_one_of :code, :id
        end
        delete "/" do
          begin
            uc =  if params[:id]
              CurriculumUnit.find(params[:id])
            else
              CurriculumUnit.where("lower(code) = ?", params[:code].downcase).first
            end

            unless uc.blank?
              begin
                uc.api = true
                uc.destroy
              rescue
                uc.deactivate_all_groups
              end
            end

            {ok: :ok}
          end
        end

      end # curriculum_unit

      desc "Todas as disciplinas por tipo, semestre ou curso", hidden: true
        params do
          requires :semester, type: String
          optional :course_type_id, type: Integer#, values: -> { CurriculumUnitType.all.map(&:id) }
          optional :course_id, type: Integer#, values: -> { Course.all.map(&:id) }
        end
        get :disciplines, rabl: "curriculum_units/list" do
          tb_joins = [:semester]
          tb_joins << :course if params[:course_id].present?

          query = ["semesters.name = :semester"]
          query << "curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
          query << "courses.id = :course_id" if params[:course_id].present?

          @curriculum_units = CurriculumUnit.joins(offers: tb_joins).where(query.join(' AND '), params.slice(:semester, :course_type_id, :course_id)).order("code")
        end

    end # segment

  end
end
