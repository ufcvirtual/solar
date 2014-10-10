module V1
  class Integrations < Base
    namespace :integration

    before do
      verify_ip_access!
    end

    helpers do
      def get_event_type_and_description(type)
        case type.to_i
          when 1; {type: 2, title: "Encontro Presencial"} # encontro presencial
          when 2; {type: 1, title: "Prova Presencial: AP - 1ª chamada"} # prova presencial - AP - 1ª chamada
          when 3; {type: 1, title: "Prova Presencial: AP - 2ª chamada"} # prova presencial - AP - 2ª chamada
          when 4; {type: 1, title: "Prova Presencial: AF - 1ª chamada"} # prova presencial - AF - 1ª chamada
          when 5; {type: 1, title: "Prova Presencial: AF - 2ª chamada"} # prova presencial - AF - 2ª chamada
          when 6; {type: 5, title: "Aula por Web Conferência"} # aula por webconferência
        end
      end
    end

    namespace :event do

      # PUT integration/event/:id
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

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end # put :id

    end

    namespace :events do
      
      # POST integration/events
      params do
        requires :Turmas, type: Array
        requires :CodigoCurso, :CodigoDisciplina, :Periodo
        requires :DataInserida do
          requires :Data, :HoraInicio, :HoraFim, :Polo, :Tipo
        end
      end
      post "/" do
        groups_events_ids = []
        
        begin
          ActiveRecord::Base.transaction do
            offer      = get_offer(params[:CodigoDisciplina], params[:CodigoCurso], nil, params[:Periodo])
            event_data = params[:DataInserida]
            event_info = get_event_type_and_description(event_data[:Tipo])

            params[:Turmas].each do |code|
              start_hour, end_hour = event_data[:HoraInicio].split(":"), event_data[:HoraFim].split(":")
              group    = get_offer_group(offer, code)
              schedule = Schedule.create! start_date: event_data[:Data], end_date: event_data[:Data]
              event    = ScheduleEvent.create! title: event_info[:title], type_event: event_info[:type],
                place: event_data[:Polo], start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":"),
                schedule_id: schedule.id, integrated: true
              event.academic_allocations.create! allocation_tag_id: group.allocation_tag.id
              groups_events_ids << {Codigo: group.code, id: event.id}
            end
          end

          groups_events_ids
        rescue => error
          error!({error: error}, 422)
        end

      end # /

      # DELETE integration/events/:ids
      params { requires :ids, type: String, desc: "Events IDs." }
      delete "/:ids" do
        begin
          ScheduleEvent.transaction do
            ScheduleEvent.where(id: params[:ids].split(",")).destroy_all
          end

          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end # delete :id

    end

    namespace :user do
      
      # POST integration/user
      params do
        requires :name, :nick, :birthdate, :gender, :cpf, :email
      end

      post "/" do
        begin
          ActiveRecord::Base.transaction do
            new_password = ('0'..'z').to_a.shuffle.first(8).join
            user = User.new name: params[:name], nick: params[:nick], username: (params.include?(:username) ? params[:username] : params[:cpf]), birthdate: params[:birthdate], gender: params[:gender], 
              cpf: params[:cpf], email: params[:email], password: new_password, cell_phone: params[:cell_phone], telephone: params[:telephone], special_needs: params[:special_needs], address: params[:address],
              address_number: params[:address_number], zipcode: params[:zipcode], address_neighborhood: params[:address_neighborhood], country: params[:country], state: params[:state], city: params[:city]
            user.synchronizing = true # ignore MA
            user.save!

            user.update_attribute :password, nil

            Thread.new do
              Mutex.new.synchronize {
                Notifier.new_user(user, new_password).deliver
              }
            end
          end

        rescue => error
          error!({error: error}, 422)
        end

      end # /

    end # user


    namespace :groups do

      # integration/groups/merge
      namespace :merge do
        params do
          requires :main_group, type: String  
          requires :secundary_groups, type: Array
          requires :course, :curriculum_unit, :period
          requires :type_merge, type: Boolean # if true: merge; if false: undo merge
        end

        put "/" do
          begin
            if params[:type_merge]
              replicate_content_groups, receive_content_groups = params[:secundary_groups], [params[:main_group]]
            else
              replicate_content_groups, receive_content_groups = [params[:main_group]], params[:secundary_groups]
            end

            offer = get_offer(params[:curriculum_unit], params[:course], nil, params[:period])
            ActiveRecord::Base.transaction do
              replicate_content_groups.each do |replicate_content_group_code|
                replicate_content_group = get_offer_group(offer, replicate_content_group_code)
                receive_content_groups.each do |receive_content_group_code|
                  receive_content_group = get_offer_group(offer, receive_content_group_code)
                  replicate_content(replicate_content_group, receive_content_group, params[:type_merge])
                end
              end
            end
            offer.notify_editors_of_disabled_groups(Group.where(code: params[:secundary_groups])) if params[:type_merge]

            {ok: :ok}
          rescue ActiveRecord::RecordNotFound
            error!({error: I18n.t(:object_not_found)}, 404)
          rescue => error
            error!({error: error}, 422)
          end
        end # /

      end # merge

    end # groups

    namespace :course do 
      desc "Criação de curso"
      params { requires :name, :code }
      post "/" do
        begin
          course = Course.create! params.except("route_info")
          {id: course.id}
        rescue => error
          render json: {errors: error}, status: 422
        end
      end

      desc "Edição de curso"
      params { optional :name, :code }
      put ":id" do
        # se for livre, não deixa
        begin
          Course.find(params[:id]).update_attributes! params.except("route_info")
          {ok: :ok}
        rescue
          render json: {errors: error}, status: 422
        end
      end
    end # course

    namespace :curriculum_unit do 
      desc "Criação de disciplina"
      params do
        requires :name, :code, type: String
        requires :curriculum_unit_type_id, type: Integer
        optional :resume, :syllabus, :objectives
        optional :passing_grade, :prerequisites, :working_hours, :credits
      end
      post "/" do
        begin
          ActiveRecord::Base.transaction do
            attributes = {resume: params[:name], syllabus: params[:name], objectives: params[:name]}
            uc     = CurriculumUnit.create! attributes.merge!(params.except("route_info"))
            course = Course.create! name: params[:name], code: params[:code] if params[:curriculum_unit_type_id] == 3 # se curso livre
            {id: uc.id, course_id: course.try(:id)}
          end
        rescue => error
          render json: {errors: error}, status: 422
          # error!({error: uc.errors}, 422)
        end
      end

      desc "Edição de disciplina"
      params do
        optional :name, :code
        optional :resume, :syllabus, :objectives
        optional :passing_grade, :prerequisites, :working_hours, :credits
        # reject uc_type
      end
      put ":id" do
        begin
          ActiveRecord::Base.transaction do
            uc = CurriculumUnit.find(params[:id])
            course = Course.find_by_code(uc.code)
            uc.update_attributes! params.except("route_info")
            course.update_attributes! code: uc.code, name: uc.name unless uc.curriculum_unit_type_id != 3
            {ok: :ok}
          end
        rescue => error
          render json: {errors: error}, status: 422
        end
      end
    end # curriculum_unit

    namespace :offer do 
      desc "Criação de oferta/semestre"
      params do
        requires :name, type: String
        requires :course_id, type: Integer
        requires :curriculum_unit_id, type: Integer
        requires :offer_start, type: Date
        requires :offer_end, type: Date
        optional :enrollment_start, type: Date
        optional :enrollment_end, type: Date
      end
      post "/" do
        begin        
          offer = creates_offer_and_semester(params[:name], {start_date: params[:offer_start].try(:to_date), end_date: params[:offer_end].try(:to_date)}, {start_date: params[:enrollment_start], end_date: params[:enrollment_end]}, {curriculum_unit_id: params[:curriculum_unit_id], course_id: params[:course_id]})
          {id: offer.id}
        rescue => error
          render json: {errors: error}, status: 422
        end
      end

      desc "Edição de oferta/semestre"
      # não edita nome do semestre. se for o caso, deleta a antiga oferta e cria uma nova com o nome certo do semestre
      params do
        optional :offer_start, type: Date
        optional :offer_end, type: Date
        optional :enrollment_start, type: Date
        optional :enrollment_end, type: Date
      end
      put ":id" do
        begin
          offer = Offer.find(params[:id])
          semester = offer.semester

          offer_period      = {start_date: params[:offer_start] || semester.offer_schedule.start_date, end_date: params[:offer_end] || semester.enrollment_schedule.start_date}
          enrollment_period = {start_date: params[:enrollment_start] || semester.enrollment_schedule.start_date, end_date: params[:enrollment_end] || semester.enrollment_schedule.end_date}

          # se veio pra edição, obrigatoriamente vai editar alguma data
          (offer.period_schedule.nil? ? offer.build_period_schedule(offer_period) : offer.period_schedule.update_attributes!(offer_period)) if params[:offer_start].present? or params[:offer_end].present?
          (offer.enrollment_schedule.nil? ? offer.build_enrollment_schedule(enrollment_period) : offer.enrollment_schedule.update_attributes!(enrollment_period)) if params[:enrollment_start].present? or params[:enrollment_end].present?

          offer.save!
          
          {ok: :ok}
        rescue => error
          error!({error: error}, 422)
        end
      end
    end # offer

    namespace :group do 
      desc "Criação de turma"
      params do
        requires :code, type: String
        requires :offer_id, type: Integer
      end
      post "/" do
        begin
          group = Group.create! params.except("route_info").merge!({status: true})     
          {id: group.id}
        rescue => error
          render json: {errors: error}, status: 422
        end
      end

      desc "Edição de turma"
      # não edita nome do semestre. se for o caso, deleta a antiga oferta e cria uma nova com o nome certo do semestre
      params do
        optional :code, type: String
        optional :status, type: Boolean
      end
      put ":id" do
        begin
          Group.find(params[:id]).update_attributes! params.except("route_info")
          # mandar email pros editores se desativar
          
          {ok: :ok}
        rescue => error
          render json: {errors: error}, status: 422
        end
      end
    end # group

    namespace :allocation do 
      desc "Alocação de usuário"
      params do
        requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"], default: "group"
        requires :user_id, type: Integer
        requires :profile_id, type: Integer
        requires :remove_previous_allocations, type: Boolean, default: false
      end
      post ":id" do
        begin
          object = params[:type].capitalize.constantize.find(params[:id])
          object.allocate_user(params[:user_id], params[:profile_id])
          object.remove_allocations(params[:profile_id]) if params[:remove_previous_allocations]

          {ok: :ok}
        rescue => error
          render json: {errors: error}, status: 422
        end
      end

      desc "Desativação de alocação de usuário"
      params do
        requires :type, type: String, values: ["curriculum_unit_type", "curriculum_unit", "course", "offer", "group"], default: "group"
        requires :user_id, type: Integer
        optional :profile_id, type: Integer
      end
      delete ":id" do
        begin
          object = params[:type].capitalize.constantize.find(params[:id])
          object.unallocate_user(params[:user_id], params[:profile_id])

          {ok: :ok}
        rescue => error
          render json: {errors: error}, status: 422
        end
      end
    end # allocation

  end
end
