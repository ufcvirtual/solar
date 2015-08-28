module V1
  class RemoveAfterChanges < Base

    before { verify_ip_access! }

    namespace :load do

        namespace :groups do

          # load/groups/allocate_user
          # params { requires :cpf, :perfil, :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano }
          put :allocate_user do # Receives user's cpf, group and profile to allocate
            begin
              allocation = params[:allocation]
              user       = verify_or_create_user(allocation[:cpf])
              profile_id = get_profile_id(allocation[:perfil])

              destination = get_destination(allocation[:codDisciplina], allocation[:codGraduacao], allocation[:codTurma], (allocation[:periodo].blank? ? allocation[:ano] : "#{allocation[:ano]}.#{allocation[:periodo]}"))
              destination.allocate_user(user.id, profile_id)

              {ok: :ok}
            end
          end # allocate_profile

          # load/groups/block_profile
          put :block_profile do # Receives user's cpf, group and profile to block
            allocation = params[:allocation]
            user       = User.find_by_cpf!(allocation[:cpf].to_s.delete('.').delete('-'))
            group_info = allocation[:turma]
            profile_id = get_profile_id(allocation[:perfil])

            begin
              destination = get_destination(group_info[:codDisciplina], group_info[:codGraduacao], group_info[:codigo], (group_info[:periodo].blank? ? group_info[:ano] : "#{group_info[:ano]}.#{group_info[:periodo]}"))
              destination.cancel_allocations(user.id, profile_id) if destination

              {ok: :ok}
            end
          end # block_profile

        end # groups

        namespace :curriculum_units do
          # load/curriculum_units/editors
          post :editors do
            load_editors  = params[:editores]
            uc            = CurriculumUnit.find_by_code!(load_editors[:codDisciplina])
            cpf_editores  = load_editors[:editores].map {|c| c.delete('.').delete('-')}

            begin
              User.where(cpf: cpf_editores).each do |user|
                uc.allocate_user(user.id, 5)
              end

              {ok: :ok}
            end
          end

          # load/curriculum_units
          params do 
            requires :codigo, :nome, type: String
            requires :cargaHoraria, type: Integer
            requires :creditos, type: Float
            optional :tipo, type: Integer, default: 2
          end
          post "/" do
            begin
              ActiveRecord::Base.transaction do 
                verify_or_create_curriculum_unit( {
                  code: params[:codigo].slice(0..39), name: params[:nome], working_hours: params[:cargaHoraria], credits: params[:creditos], curriculum_unit_type_id: params[:tipo]
                } )
              end
              {ok: :ok}
            end
          end

        end # curriculum_units

        namespace :groups do
          # POST load/groups
          post "/" do
            load_group    = params[:turmas]
            cpfs          = load_group[:professores]
            semester_name = load_group[:periodo].blank? ? load_group[:ano] : "#{load_group[:ano]}.#{load_group[:periodo]}"
            offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: load_group[:dtFim].to_date }
            course        = Course.find_by_code! load_group[:codGraduacao]
            uc            = CurriculumUnit.find_by_code! load_group[:codDisciplina]

            begin
              ActiveRecord::Base.transaction do
                semester = verify_or_create_semester(semester_name, offer_period)
                offer    = verify_or_create_offer(semester, {curriculum_unit_id: uc.id, course_id: course.id}, offer_period)
                group    = verify_or_create_group({offer_id: offer.id, code: load_group[:codigo]})

                allocate_professors(group, cpfs)
              end

              { ok: :ok }
            end
          end

          # POST load/groups/enrollments
          post :enrollments do
            load_enrollments = params[:matriculas]
            user             = verify_or_create_user(load_enrollments[:cpf])
            groups           = JSON.parse(load_enrollments[:turmas])
            student_profile  = 1 # Aluno => 1

            begin
              ActiveRecord::Base.transaction do

                groups = groups.collect do |group_info|
                  get_group_by_codes(group_info["codDisciplina"], group_info["codGraduacao"], group_info["codigo"], (group_info["periodo"].blank? ? group_info["ano"] : "#{group_info["ano"]}.#{group_info["periodo"]}")) unless group_info["codDisciplina"] == 78
                end # Se cód. graduação for 78, desconsidera (por hora, vem por engano).

                cancel_previous_and_create_allocations(groups.compact, user, student_profile)
              end

              { ok: :ok }
            end
          end

          # PUT load/groups/:semester/cancel_students_enrollments
          params{ requires :semester, type: String }
          put ':semester/cancel_students_enrollments' do
            begin
              ActiveRecord::Base.transaction do
                semester = Semester.find_by_name(params[:semester])
                cancel_all_allocations(1, semester.id) # Aluno => 1
              end

              { ok: :ok }
            end
          end

          # GET load/groups/enrollments
          params { requires :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano, type: String }
          get :enrollments, rabl: "users/list" do
            group  = get_group_by_codes(params[:codDisciplina], params[:codGraduacao], params[:codTurma], (params[:periodo].blank? ? params[:ano] : "#{params[:ano]}.#{params[:periodo]}"))
            raise ActiveRecord::RecordNotFound if group.nil?
            begin
              @users = group.students_participants
            end
          end

        end # groups

        namespace :user do
          params { requires :cpf, type: String }
          # load/user
          post "/" do
            begin
              user = User.new cpf: params[:cpf]
              ma_response = user.connect_and_validates_user
              raise ActiveRecord::RecordNotFound if ma_response.nil? # nao existe no MA
              { ok: :ok }
            end
          end
        end # user

      end # load

      namespace :integration do 

        namespace :event do

          desc "Edição de evento"
          params do
            requires :id, type: Integer, desc: "Event ID."
            requires :Data, :HoraInicio, :HoraFim
          end
          put "/:id" do
            begin
              event = ScheduleEvent.find(params[:id])

              ActiveRecord::Base.transaction do
                start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
                event.schedule.update_attributes! start_date: params[:Data], end_date: params[:Data]
                event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":")
              end

              { ok: :ok }
            end
          end # put :id

        end # event

        namespace :events do
          
          desc "Criação de um ou mais eventos"
          params do
            requires :Turmas, type: Array
            requires :CodigoCurso, :CodigoDisciplina, :Periodo, type: String
            requires :DataInserida, type: Hash do
              requires :Data
              requires :HoraInicio, :HoraFim, :Polo, :Tipo, type: String
            end
          end
          post "/" do
            group_events = []
            
            begin
              ActiveRecord::Base.transaction do
                offer = get_offer(params[:CodigoDisciplina], params[:CodigoCurso], params[:Periodo])
                params[:Turmas].each do |code|
                  group_events << create_event1(get_offer_group(offer, code), params[:DataInserida])
                end
              end

              group_events
            end

          end # /

          desc "Remoção de um ou mais eventos"
          params { requires :ids, type: String, desc: "Events IDs." }
          delete "/:ids" do
            begin
              ScheduleEvent.transaction do
                ScheduleEvent.where(id: params[:ids].split(",")).destroy_all
              end

              {ok: :ok}
            end
          end # delete :id

        end # events

      end # integration

  end
end