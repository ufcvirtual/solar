module V1
  class RemoveAfterChanges < Base

    before { verify_ip_access_and_guard! }

    namespace :load do

        namespace :groups do

          # load/groups/allocate_user
          # params { requires :cpf, :perfil, :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano }
          put :allocate_user do # Receives user's cpf, group and profile to allocate
            begin
              allocation = params[:allocation]
              user       = verify_or_create_user(allocation[:cpf])
              profile_id = get_profile_id(allocation[:perfil])

              raise "user #{allocation[:cpf]} doesn't exist" if user.blank? || user.id.blank?

              destination = get_destination(allocation[:codDisciplina], allocation[:codGraduacao], allocation[:nomeTurma], (allocation[:periodo].blank? ? allocation[:ano] : "#{allocation[:ano]}.#{allocation[:periodo]}"))

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
              destination = get_destination(group_info[:codDisciplina], group_info[:codGraduacao], group_info[:nome], (group_info[:periodo].blank? ? group_info[:ano] : "#{group_info[:ano]}.#{group_info[:periodo]}"))

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
            offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: (load_group[:dtFim].to_date) }
            course        = Course.find_by_code! load_group[:codGraduacao]
            uc            = CurriculumUnit.find_by_code! load_group[:codDisciplina]

            begin
              group = nil
              if load_group[:name].blank?
                load_group[:name] = load_group[:codigo]
                load_group[:code] = load_group[:codigo]
              end

              ActiveRecord::Base.transaction do
                semester = verify_or_create_semester(semester_name, offer_period)
                offer    = verify_or_create_offer(semester, {curriculum_unit_id: uc.id, course_id: course.id}, offer_period)
                load_group[:code] = get_group_code(load_group[:code], load_group[:name]) unless load_group[:code].blank? || load_group[:name].blank?

                group    = verify_or_create_group({offer_id: offer.id, code: load_group[:code], name: load_group[:name], location_name: load_group[:location_name], location_office: load_group[:location_office]})
              end

              allocate_professors(group, cpfs || [])

              { ok: :ok }
            end
          end

          segment do
            params{ requires :matriculas }
            before do
              load_enrollments = params[:matriculas]
              @user             = verify_or_create_user(load_enrollments[:cpf])
              @groups           = JSON.parse(load_enrollments[:turmas])
              @student_profile  = 1 # Aluno => 1

              @groups = @groups.collect do |group_info|
                group_info["nome"] = group_info["codigo"] if group_info["nome"].blank?
                get_group_by_names(group_info["codDisciplina"], group_info["codGraduacao"], group_info["nome"], (group_info["periodo"].blank? ? group_info["ano"] : "#{group_info["ano"]}.#{group_info["periodo"]}")) unless group_info["codDisciplina"] == 78
              end # Se cód. graduação for 78, desconsidera (por hora, vem por engano).

              raise ActiveRecord::RecordNotFound if @groups.include?(nil)
            end # before

            # POST load/groups/enrollments
            post :enrollments do
              begin
                create_allocations(@groups.compact, @user, @student_profile)

                { ok: :ok }
              end
            end

            # DELETE load/groups/enrollments
            delete :enrollments do
              begin
                cancel_allocations(@groups.compact, @user, @student_profile)

                { ok: :ok }
              end
            end

          end # segment

          # PUT load/groups/cancel_students_enrollments
          params{ requires :semester, type: String }
          put :cancel_students_enrollments do
            begin
              ActiveRecord::Base.transaction do
                semester = Semester.find_by_name(params[:semester])
                cancel_all_allocations(1, semester.id) # Aluno => 1
              end

              { ok: :ok }
            end
          end

          # GET load/groups/enrollments
          params { requires :codDisciplina, :codGraduacao, :nomeTurma, :periodo, :ano, type: String }
          get :enrollments, rabl: "users/list" do
            group  = get_group_by_names(params[:codDisciplina], params[:codGraduacao], params[:nomeTurma], (params[:periodo].blank? ? params[:ano] : "#{params[:ano]}.#{params[:periodo]}"))
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
              # event = ScheduleEvent.find(params[:id])
              ac = AcademicAllocation.where(id: params[:id], academic_tool_type: 'ScheduleEvent').first
              raise ActiveRecord::RecordNotFound if ac.blank?
              event = ScheduleEvent.find(ac.academic_tool_id)

              ActiveRecord::Base.transaction do
                start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
                create_event({event: {date: params[:Data], start: params[:HoraInicio], end: params[:HoraFim], title: event.title, type_event: event.type_event}}, ac.allocation_tag.group.offer.allocation_tag.related, nil, ac, (event.academic_allocations.count == 1 ? event : nil))
                # event.schedule.update_attributes! start_date: params[:Data], end_date: params[:Data]
                # event.api = true
                # event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":")
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
                group_events = create_event(params, offer.allocation_tag.related, offer)
                # params[:Turmas].each do |group_name|
                #   group = get_offer_group(offer, group_name)
                #   group_events << create_event1(get_offer_group(offer, group_name), params[:DataInserida])
                # end
              end

              group_events
            end

          end # /

          desc "Remoção de um ou mais acs de eventos"
          params { requires :ids, type: String, desc: "Events IDs." }
          delete "/:ids" do
            begin
              AcademicAllocation.transaction do
                acs = AcademicAllocation.where(id: params[:ids].split(','), academic_tool_type: 'ScheduleEvent')
                raise ActiveRecord::RecordNotFound if acs.empty?
                event = ScheduleEvent.find(acs.first.academic_tool_id)

                if acs.count == event.academic_allocations.count
                  event.api = true
                  raise event.errors.full_messages unless event.destroy
                else
                  acs.destroy_all
                end
              end
              # ScheduleEvent.transaction do
              #   ScheduleEvent.where(id: params[:ids].split(",")).each do |event|
              #     event.api = true
              #     raise event.errors.full_messages unless event.destroy
              #   end
              # end

              {ok: :ok}
            end
          end # delete :id

        end # events

      end # integration

  end
end