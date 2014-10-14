module V1
  class CurriculumUnits < Base
    
    segment do
      before do
        guard!

        user_groups    = current_user.groups(nil, Allocation_Activated).map(&:id)
        current_offers = Offer.currents(Date.today, true).pluck(:id)

        @u_groups         = Group.where(id: user_groups, offer_id: current_offers)
        @curriculum_units = CurriculumUnit.joins(:groups).where(groups: {id: @u_groups.map(&:id)}).uniq.order(:name)
      end

      namespace :curriculum_units do

        desc "Lista UCs da oferta vigente."
        get "/", rabl: "curriculum_units/list" do # Futuramente, poderemos especificar outra oferta
          # @curriculum_units
        end

        desc "Lista UCs da oferta vigente incluindo as turmas"
        get "groups", rabl: "curriculum_units/list_with_groups" do
          # @curriculum_units, @u_groups
        end

      end # curriculum_units

    end # segment

    segment do

      before { verify_ip_access! }

      namespace :integration do 

        namespace :curriculum_unit do 
          desc "Criação de disciplina"
          params do
            requires :name, :code, type: String
            requires :curriculum_unit_type_id, type: Integer, default: 2
            optional :resume, :syllabus, :objectives, :passing_grade, :prerequisites, :working_hours, :credits
          end
          post "/" do
            begin
              uc = CurriculumUnit.create! curriculum_unit_params(params, true)
              {id: uc.id, course_id: uc.course.try(:id)}
            rescue => error
              error!(error, 422)
            end
          end

          desc "Edição de disciplina"
          params do
            optional :name, :code
            optional :resume, :syllabus, :objectives, :passing_grade, :prerequisites, :working_hours, :credits
            # reject uc_type # nao poderia mudar tipo depois de criado
          end
          put ":id" do
            begin
              CurriculumUnit.find(params[:id]).update_attributes! curriculum_unit_params(params)
              {ok: :ok}
            rescue => error
              error!(error, 422)
            end
          end
        end # curriculum_unit

      end # integration

      namespace :load do

        namespace :curriculum_units do
          # load/curriculum_units
          params do 
            requires :codigo, :nome, type: String
            requires :cargaHoraria, type: Integer
            requires :creditos, type: Float
            optional :tipo, type: Integer
          end
          post "/" do
            begin
              ActiveRecord::Base.transaction do 
                verify_or_create_curriculum_unit(params[:codigo], params[:nome], params[:cargaHoraria], params[:creditos], (params[:tipo].nil? ? 2 : params[:tipo]))
              end
              {ok: :ok}
            rescue => error
              error!({error: error}, 422)
            end
          end
        end #curriculum_units

      end # load

      namespace :sav do

        desc "Todas as disciplinas por tipo, semestre ou curso"
        params do
          requires :semester, type: String
          optional :course_type_id, :course_id, type: Integer
        end
        get :disciplines, rabl: "sav/disciplines" do
          tb_joins = [:semester]
          tb_joins << :course if params[:course_id].present?

          query = ["semesters.name = :semester"]
          query << "curriculum_unit_type_id = :course_type_id" if params[:course_type_id].present?
          query << "courses.id = :course_id" if params[:course_id].present?

          @disciplines = CurriculumUnit.joins(offers: tb_joins).where(query.join(' AND '), params.slice(:semester, :course_type_id, :course_id))
        end

        desc "Todos os tipos de curso"
        get "/course/types", rabl: "sav/course_types" do
          @types = CurriculumUnitType.all
        end

      end # sav

    end # segment

  end
end
