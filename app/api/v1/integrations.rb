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

      # # PUT integration/event/:id
      # params do
      #   requires :id, type: Integer, desc: "Event ID."
      #   requires :DataInicio, :Tipo, :HoraInicio, :HoraFim, :Polo
      # end
      # put ":id" do
      #   begin
      #     event = ScheduleEvent.find(params[:id])

      #     ActiveRecord::Base.transaction do
      #       event.schedule.update_attributes! start_date: event[:DataInicio], end_date: (event.include?(:DataFim) ? event[:DataFim] : event[:DataInicio])
      #       event.update_attributes! place: event[:Polo], start_hour: event[:HoraInicio], end_hour: event[:HoraFim]
      #     end

      #     {ok: :ok}
      #   rescue => error
      #     raise "Erro: #{error}"
      #     error!({error: error}, 422)
      #   end
      # end # put :id

    end

    namespace :events do
      
      # POST integration/events
      params do
        requires :Turmas, type: Array
        requires :DataInserida, :CodigoCurso, :CodigoDisciplina, :Periodo
      end
      post "/" do
        groups_events_ids = []
        
        begin
          ActiveRecord::Base.transaction do
            offer      = get_offer(params[:CodigoDisciplina], params[:CodigoCurso], nil, params[:Periodo])
            event_data = params[:DataInserida]
            event_info = get_event_type_and_description(event_data[:Tipo])

            params[:Turmas].each do |code|
              group    = get_offer_group(offer, code)
              schedule = Schedule.create! start_date: event_data[:Data], end_date: event_data[:Data]
              event    = ScheduleEvent.create! title: event_info[:title], type_event: event_info[:type],
                place: event_data[:Polo], start_hour: event_data[:HoraInicio], end_hour: event_data[:HoraFim], sechedule_id: schedule.id, integrated: true
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
      delete ":ids" do
        begin
          ScheduleEvent.transaction do
            ScheduleEvent.where(id: params[:ids].split(",")).destroy_all
          end

          {ok: :ok}
        rescue => error
          raise "erro#{error}"
          error!({error: error}, 422)
        end
      end # put :id

    end

  end
end