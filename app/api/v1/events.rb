module V1
  class Events < Base

    segment do

      before { verify_ip_access! }

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

              {ok: :ok}
            rescue => error
              error!({error: error}, 422)
            end
          end # put :id

        end # event

        namespace :events do
          
          desc "Criação de um ou mais eventos"
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

          desc "Remoção de um ou mais eventos"
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

        end # events

      end # integration

    end # segment

  end
end