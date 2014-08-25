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

    end

  end
end